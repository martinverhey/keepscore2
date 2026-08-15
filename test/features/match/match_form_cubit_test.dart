import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.dart';
import 'package:keepscore2/features/match/domain/match_entry.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_form_cubit.dart';
import 'package:keepscore2/features/player/domain/player.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

Competition _competition({bool allowDraws = true}) => Competition(
  id: 'c1',
  joinCode: 'HDHS39',
  name: 'Office Table Tennis',
  ownerId: 'u1',
  seasonLength: SeasonLength.monthly,
  timezone: 'Europe/Amsterdam',
  startingRating: 1000,
  kFactor: 32,
  movEnabled: false,
  movCap: 2.5,
  allowDraws: allowDraws,
  createdAt: DateTime(2026),
);

Player _player(String id, String name, {bool isActive = true}) =>
    Player(id: id, competitionId: 'c1', displayName: name, isActive: isActive);

Leaderboard _standing(String playerId, double rating) => Leaderboard(
  seasonId: 's1',
  competitionId: 'c1',
  playerId: playerId,
  displayName: playerId,
  isClaimed: true,
  isOwner: false,
  rating: rating,
  played: 1,
  wins: 1,
  losses: 0,
  draws: 0,
  rank: 1,
);

void main() {
  late MockMatchRepository matches;
  late MockCompetitionRepository competitions;
  late MockPlayerRepository players;
  late MockLeaderboardRepository leaderboard;

  MatchFormCubit build() =>
      MatchFormCubit(matches, competitions, players, leaderboard, 'c1');

  void stubLoad({
    Competition? competition,
    List<Player>? roster,
    List<Leaderboard> standings = const [],
  }) {
    when(() => competitions.overview('c1')).thenAnswer(
      (_) async => CompetitionOverview(
        competition: competition ?? _competition(),
        playerCount: 2,
        matchCount: 0,
      ),
    );
    when(() => players.roster('c1')).thenAnswer(
      (_) async => roster ?? [_player('p1', 'Ada'), _player('p2', 'Grace')],
    );
    when(() => leaderboard.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(
        id: 's1',
        startsAt: DateTime(2026, 8),
        endsAt: DateTime(2026, 9),
      ),
    );
    when(
      () => leaderboard.standings(competitionId: 'c1', seasonId: 's1'),
    ).thenAnswer((_) async => standings);
  }

  setUp(() {
    matches = MockMatchRepository();
    competitions = MockCompetitionRepository();
    players = MockPlayerRepository();
    leaderboard = MockLeaderboardRepository();
  });

  blocTest<MatchFormCubit, MatchFormState>(
    'loads the active roster and this season\'s ratings',
    setUp: () => stubLoad(
      roster: [
        _player('p1', 'Ada'),
        _player('p2', 'Grace'),
        _player('p3', 'Zoe', isActive: false),
      ],
      standings: [_standing('p1', 1040)],
    ),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, MatchFormStatus.ready);
      expect(cubit.state.players.map((player) => player.id), ['p1', 'p2']);
      expect(cubit.state.ratingOf('p1'), 1040);
      expect(cubit.state.ratingOf('p2'), 1000);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'a failed load is reported instead of an empty form',
    setUp: () {
      stubLoad();
      when(() => players.roster('c1')).thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, MatchFormStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'refreshing players picks up a rename without disturbing assignments',
    setUp: () =>
        stubLoad(roster: [_player('p1', 'Ada'), _player('p2', 'Grace')]),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.scoreAChanged('11');
      when(() => players.roster('c1')).thenAnswer(
        (_) async => [_player('p1', 'Adaeze'), _player('p2', 'Grace')],
      );
      await cubit.refreshPlayers();
    },
    verify: (cubit) {
      expect(cubit.state.players.map((player) => player.displayName), [
        'Adaeze',
        'Grace',
      ]);
      expect(cubit.state.teamA.map((player) => player.id), ['p1']);
      expect(cubit.state.scoreA, '11');
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'a failed refresh keeps the roster already on screen',
    setUp: stubLoad,
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(() => players.roster('c1')).thenThrow(const NetworkFailure());
      await cubit.refreshPlayers();
    },
    verify: (cubit) {
      expect(cubit.state.players.map((player) => player.id), ['p1', 'p2']);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'tapping the side a player is already on takes them off',
    setUp: stubLoad,
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p1', MatchTeam.b);
      cubit.assign('p1', MatchTeam.b);
    },
    verify: (cubit) {
      expect(cubit.state.assignments, isEmpty);
      expect(cubit.state.bench.map((player) => player.id), ['p1', 'p2']);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'setting a team replaces its members and moves anyone picked off the other side',
    setUp: () => stubLoad(
      roster: [
        _player('p1', 'Ada'),
        _player('p2', 'Grace'),
        _player('p3', 'Zoe'),
      ],
    ),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.setTeam(MatchTeam.a, ['p1', 'p2']);
      cubit.setTeam(MatchTeam.b, ['p2', 'p3']);
    },
    verify: (cubit) {
      expect(cubit.state.teamA.map((player) => player.id), ['p1']);
      expect(cubit.state.teamB.map((player) => player.id), ['p2', 'p3']);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'a match needs a player on each side and two scores',
    setUp: stubLoad,
    build: build,
    act: (cubit) async {
      await cubit.load();
      expect(cubit.state.canSubmit, isFalse);
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
      expect(cubit.state.canSubmit, isFalse);
      cubit.scoreAChanged('11');
      expect(cubit.state.canSubmit, isFalse);
      cubit.scoreBChanged('7');
    },
    verify: (cubit) => expect(cubit.state.canSubmit, isTrue),
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'a draw cannot be submitted when the competition refuses draws',
    setUp: () => stubLoad(competition: _competition(allowDraws: false)),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
      cubit.scoreAChanged('7');
      cubit.scoreBChanged('7');
    },
    verify: (cubit) {
      expect(cubit.state.drawIsRefused, isTrue);
      expect(cubit.state.canSubmit, isFalse);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'the preview is the competition\'s own Elo settings applied locally',
    setUp: stubLoad,
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
      cubit.scoreAChanged('11');
      cubit.scoreBChanged('7');
    },
    verify: (cubit) {
      final preview = cubit.state.preview!;
      expect(preview.teamARating, 1000);
      expect(preview.teamBRating, 1000);
      expect(preview.deltaA, 16);
      expect(preview.deltaB, -16);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'submitting sends both rosters and the scores',
    setUp: () {
      stubLoad(
        roster: [
          _player('p1', 'Ada'),
          _player('p2', 'Grace'),
          _player('p3', 'Zoe'),
        ],
      );
      when(
        () => matches.create(
          competitionId: any(named: 'competitionId'),
          teamA: any(named: 'teamA'),
          teamB: any(named: 'teamB'),
          scoreA: any(named: 'scoreA'),
          scoreB: any(named: 'scoreB'),
        ),
      ).thenAnswer((_) async => 'm1');
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p3', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
      cubit.scoreAChanged('11');
      cubit.scoreBChanged('7');
      expect(await cubit.submit(), 'm1');
    },
    verify: (cubit) {
      verify(
        () => matches.create(
          competitionId: 'c1',
          teamA: ['p1', 'p3'],
          teamB: ['p2'],
          scoreA: 11,
          scoreB: 7,
        ),
      ).called(1);
      expect(cubit.state.busy, isFalse);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'a rejected submit is reported without clearing the form',
    setUp: () {
      stubLoad();
      when(
        () => matches.create(
          competitionId: any(named: 'competitionId'),
          teamA: any(named: 'teamA'),
          teamB: any(named: 'teamB'),
          scoreA: any(named: 'scoreA'),
          scoreB: any(named: 'scoreB'),
        ),
      ).thenThrow(const ValidationFailure('Create an account to log matches'));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
      cubit.scoreAChanged('11');
      cubit.scoreBChanged('7');
      expect(await cubit.submit(), isNull);
    },
    verify: (cubit) {
      expect(cubit.state.submitFailure, isA<ValidationFailure>());
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.teamA, hasLength(1));
      expect(cubit.state.scoreA, '11');
    },
  );
}
