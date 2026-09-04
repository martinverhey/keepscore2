import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_detail_cubit.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

MatchEntry _match({int scoreA = 11, int scoreB = 7}) => MatchEntry(
  id: 'm1',
  competitionId: 'c1',
  seasonId: 's1',
  playedAt: DateTime(2026, 8, 9, 20),
  teamAScore: scoreA,
  teamBScore: scoreB,
  teamARating: 1000,
  teamBRating: 1000,
  createdBy: 'u2',
  teamA: const [
    MatchParticipant(
      playerId: 'p1',
      displayName: 'Ada',
      ratingBefore: 1000,
      ratingDelta: 16,
    ),
  ],
  teamB: const [
    MatchParticipant(
      playerId: 'p2',
      displayName: 'Grace',
      ratingBefore: 1000,
      ratingDelta: -16,
    ),
  ],
);

CompetitionOverview _overview() => CompetitionOverview(
  competition: Competition(
    id: 'c1',
    joinCode: 'HDHS39',
    name: 'Office Table Tennis',
    ownerId: 'u1',
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    allowDraws: true,
    createdAt: DateTime(2026),
  ),
  playerCount: 2,
  matchCount: 1,
);

List<Player> _players() => const [
  Player(
    id: 'p1',
    competitionId: 'c1',
    displayName: 'Ada',
    isActive: true,
    userId: 'u2',
  ),
  Player(
    id: 'p2',
    competitionId: 'c1',
    displayName: 'Grace',
    isActive: true,
  ),
];

void main() {
  late MockMatchRepository matches;
  late MockCompetitionRepository competitions;
  late MockPlayerRepository players;

  MatchDetailCubit build() =>
      MatchDetailCubit(matches, competitions, players, 'm1', 'c1');

  setUp(() {
    matches = MockMatchRepository();
    competitions = MockCompetitionRepository();
    players = MockPlayerRepository();
    when(
      () => competitions.overview('c1'),
    ).thenAnswer((_) async => _overview());
    when(
      () => players.currentPlayers('c1'),
    ).thenAnswer((_) async => _players());
    when(() => players.watch(any())).thenAnswer((_) => const Stream.empty());
  });

  blocTest<MatchDetailCubit, MatchDetailState>(
    'loads the match alongside the competition that owns it',
    setUp: () =>
        when(() => matches.byId('m1')).thenAnswer((_) async => _match()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as MatchDetailReady;
      expect(state.match.teamAScore, 11);
      expect(state.createdByName, 'Ada');
      expect(state.isManageableBy('u2'), isTrue);
      expect(state.isManageableBy('u1'), isTrue);
      expect(state.isManageableBy('u3'), isFalse);
    },
  );

  blocTest<MatchDetailCubit, MatchDetailState>(
    'a deleted match reads as missing rather than as an error',
    setUp: () => when(() => matches.byId('m1')).thenAnswer((_) async => null),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(cubit.state, isA<MatchDetailMissing>()),
  );

  blocTest<MatchDetailCubit, MatchDetailState>(
    'a new score is read back from the server, not patched in',
    setUp: () {
      when(() => matches.byId('m1')).thenAnswer((_) async => _match());
      when(
        () => matches.updateScore(matchId: 'm1', scoreA: 11, scoreB: 9),
      ).thenAnswer((_) async {
        when(
          () => matches.byId('m1'),
        ).thenAnswer((_) async => _match(scoreA: 11, scoreB: 9));
      });
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      expect(await cubit.updateScore(scoreA: 11, scoreB: 9), isTrue);
    },
    verify: (cubit) {
      final state = cubit.state as MatchDetailReady;
      expect(state.match.teamBScore, 9);
      expect(state.busy, isFalse);
      verify(() => matches.byId('m1')).called(2);
    },
  );

  blocTest<MatchDetailCubit, MatchDetailState>(
    'a refused delete leaves the match on screen',
    setUp: () {
      when(() => matches.byId('m1')).thenAnswer((_) async => _match());
      when(() => matches.delete('m1')).thenThrow(
        const ValidationFailure(
          'Only the person who logged this match, or the competition owner, '
          'can remove it',
        ),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      expect(await cubit.delete(), isFalse);
    },
    verify: (cubit) {
      final state = cubit.state as MatchDetailReady;
      expect(state.actionFailure, isA<ValidationFailure>());
      expect(state.busy, isFalse);
    },
  );
}
