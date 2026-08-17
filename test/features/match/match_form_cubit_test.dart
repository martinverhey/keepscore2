import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_form_cubit.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
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

MatchFormReady _ready(MatchFormCubit cubit) => cubit.state as MatchFormReady;

Leaderboard _leaderboard(String playerId, double rating) => Leaderboard(
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
    List<Leaderboard> leaderboards = const [],
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
      () => leaderboard.leaderboards(competitionId: 'c1', seasonId: 's1'),
    ).thenAnswer((_) async => leaderboards);
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
      leaderboards: [_leaderboard('p1', 1040)],
    ),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).players.map((player) => player.id), ['p1', 'p2']);
      expect(_ready(cubit).ratingOf('p1'), 1040);
      expect(_ready(cubit).ratingOf('p2'), 1000);
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
      expect(cubit.state, isA<MatchFormFailed>());
      expect((cubit.state as MatchFormFailed).failure, isA<NetworkFailure>());
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
      when(() => players.roster('c1')).thenAnswer(
        (_) async => [_player('p1', 'Adaeze'), _player('p2', 'Grace')],
      );
      await cubit.refreshPlayers();
    },
    verify: (cubit) {
      expect(_ready(cubit).players.map((player) => player.displayName), [
        'Adaeze',
        'Grace',
      ]);
      expect(_ready(cubit).teamA.map((player) => player.id), ['p1']);
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
      expect(_ready(cubit).players.map((player) => player.id), ['p1', 'p2']);
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
      expect(_ready(cubit).assignments, isEmpty);
      expect(_ready(cubit).bench.map((player) => player.id), ['p1', 'p2']);
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
      expect(_ready(cubit).teamA.map((player) => player.id), ['p1']);
      expect(_ready(cubit).teamB.map((player) => player.id), ['p2', 'p3']);
    },
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'a match needs a player on each side and two scores',
    setUp: stubLoad,
    build: build,
    act: (cubit) async {
      await cubit.load();
      expect(
        _ready(cubit).canSubmit(scoreAValue: 11, scoreBValue: 7),
        isFalse,
      );
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
      expect(
        _ready(cubit).canSubmit(scoreAValue: null, scoreBValue: null),
        isFalse,
      );
      expect(
        _ready(cubit).canSubmit(scoreAValue: 11, scoreBValue: null),
        isFalse,
      );
    },
    verify: (cubit) => expect(
      _ready(cubit).canSubmit(scoreAValue: 11, scoreBValue: 7),
      isTrue,
    ),
  );

  blocTest<MatchFormCubit, MatchFormState>(
    'a draw cannot be submitted when the competition refuses draws',
    setUp: () => stubLoad(competition: _competition(allowDraws: false)),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
    },
    verify: (cubit) {
      expect(
        _ready(cubit).drawIsRefused(scoreAValue: 7, scoreBValue: 7),
        isTrue,
      );
      expect(
        _ready(cubit).canSubmit(scoreAValue: 7, scoreBValue: 7),
        isFalse,
      );
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
      expect(await cubit.submit(scoreA: 11, scoreB: 7), 'm1');
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
      expect(_ready(cubit).busy, isFalse);
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
      ).thenThrow(
        const ValidationFailure('Create an account to create matches'),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.assign('p1', MatchTeam.a);
      cubit.assign('p2', MatchTeam.b);
      expect(await cubit.submit(scoreA: 11, scoreB: 7), isNull);
    },
    verify: (cubit) {
      expect(_ready(cubit).submitFailure, isA<ValidationFailure>());
      expect(_ready(cubit).busy, isFalse);
      expect(_ready(cubit).teamA, hasLength(1));
    },
  );
}
