import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

Leaderboard _leaderboard(String playerId, double rating, int rank) =>
    Leaderboard(
      seasonId: 's-august',
      competitionId: 'c1',
      playerId: playerId,
      displayName: playerId,
      isClaimed: true,
      isOwner: false,
      rating: rating,
      played: 3,
      wins: 2,
      losses: 1,
      draws: 0,
      rank: rank,
    );

LeaderboardReady _ready(LeaderboardCubit cubit) =>
    cubit.state as LeaderboardReady;

void main() {
  late MockLeaderboardRepository repository;
  late StreamController<void> ticks;

  LeaderboardCubit build() => LeaderboardCubit(repository, 'c1');

  void stubSeason({String? id = 's-august'}) {
    when(() => repository.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(id: id, startsAt: _august, endsAt: _september),
    );
  }

  void stubLeaderboards(String? seasonId, List<Leaderboard> leaderboards) {
    when(
      () => repository.leaderboards(competitionId: 'c1', seasonId: seasonId),
    ).thenAnswer((_) async => leaderboards);
  }

  setUp(() {
    repository = MockLeaderboardRepository();
    ticks = StreamController<void>.broadcast();
    when(
      () => repository.watchLeaderboards(
        competitionId: any(named: 'competitionId'),
        seasonId: any(named: 'seasonId'),
      ),
    ).thenAnswer((_) => ticks.stream);
    when(() => repository.medals('c1')).thenAnswer((_) async => const []);
  });

  tearDown(() {
    ticks.close();
  });

  blocTest<LeaderboardCubit, LeaderboardState>(
    'loads the current season and its leaderboards',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [
        _leaderboard('p1', 1040, 1),
        _leaderboard('p2', 960, 2),
      ]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).season.id, 's-august');
      expect(_ready(cubit).leaderboards.first.playerId, 'p1');
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'loads medal tallies alongside leaderboards',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      when(() => repository.medals('c1')).thenAnswer(
        (_) async => const [
          Medals(playerId: 'p1', gold: 2, silver: 0, bronze: 1),
        ],
      );
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).medals['p1']?.gold, 2);
      expect(_ready(cubit).medals['p1']?.bronze, 1);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a season nobody has played yet is still offered, with no leaderboards',
    setUp: () {
      stubSeason(id: null);
      stubLeaderboards(null, const []);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(_ready(cubit).season.startsAt.isAtSameMomentAs(_august), isTrue);
      expect(_ready(cubit).season.hasStarted, isFalse);
      expect(_ready(cubit).leaderboards, isEmpty);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a rating written by someone else arrives without a gesture',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1000, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      stubLeaderboards('s-august', [
        _leaderboard('p1', 1032, 1),
        _leaderboard('p2', 968, 2),
      ]);
      ticks.add(null);
    },
    wait: const Duration(milliseconds: 600),
    verify: (cubit) {
      expect(_ready(cubit).leaderboards, hasLength(2));
      expect(_ready(cubit).leaderboards.first.rating, 1032);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'the subscription watches the current season',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      verify(
        () => repository.watchLeaderboards(
          competitionId: 'c1',
          seasonId: 's-august',
        ),
      ).called(1);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a failed silent refresh keeps the table on screen',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(
        () => repository.currentSeason('c1'),
      ).thenThrow(const NetworkFailure());
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state, isA<LeaderboardReady>());
      expect(_ready(cubit).leaderboards, hasLength(1));
    },
  );
}
