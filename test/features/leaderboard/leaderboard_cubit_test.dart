import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/rating_point.model.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

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

RatingPoint _point(double rating) => RatingPoint(
  playedAt: _august,
  ratingAfter: rating,
  ratingDelta: 10,
);

void main() {
  late MockLeaderboardRepository repository;
  late MockProfileRepository profileRepository;
  late StreamController<void> ticks;
  late StreamController<void> playerTicks;
  late Completer<List<Leaderboard>> pendingLeaderboards;

  LeaderboardCubit build() =>
      LeaderboardCubit(repository, profileRepository, 'c1');

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

  void stubTrend(List<RatingPoint> points) {
    when(
      () => profileRepository.ratingHistory(
        seasonId: any(named: 'seasonId'),
        playerId: any(named: 'playerId'),
      ),
    ).thenAnswer((_) async => points);
  }

  setUp(() {
    repository = MockLeaderboardRepository();
    profileRepository = MockProfileRepository();
    ticks = StreamController<void>.broadcast();
    playerTicks = StreamController<void>.broadcast();
    when(
      () => repository.watchLeaderboards(
        competitionId: any(named: 'competitionId'),
        seasonId: any(named: 'seasonId'),
      ),
    ).thenAnswer((_) => ticks.stream);
    when(
      () => repository.watchPlayers(competitionId: any(named: 'competitionId')),
    ).thenAnswer((_) => playerTicks.stream);
    when(() => repository.medals('c1')).thenAnswer((_) async => const []);
    stubTrend(const []);
  });

  tearDown(() {
    ticks.close();
    playerTicks.close();
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
    'a player who joins arrives without a gesture',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1000, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      stubLeaderboards('s-august', [
        _leaderboard('p1', 1000, 1),
        _leaderboard('p2', 1000, 2),
      ]);
      playerTicks.add(null);
    },
    wait: const Duration(milliseconds: 600),
    verify: (cubit) {
      expect(_ready(cubit).leaderboards, hasLength(2));
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'the players subscription outlives a season change',
    setUp: () {
      stubSeason(id: null);
      stubLeaderboards(null, [_leaderboard('p1', 1000, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      await cubit.refresh();
    },
    verify: (cubit) {
      verify(
        () => repository.watchLeaderboards(
          competitionId: 'c1',
          seasonId: any(named: 'seasonId'),
        ),
      ).called(2);
      verify(() => repository.watchPlayers(competitionId: 'c1')).called(1);
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

  blocTest<LeaderboardCubit, LeaderboardState>(
    "loads the viewer's rating history alongside the leaderboards",
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      stubTrend([_point(1010), _point(1026), _point(1040)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.setViewer('p1');
      await cubit.load();
    },
    verify: (cubit) {
      verify(
        () => profileRepository.ratingHistory(
          seasonId: 's-august',
          playerId: 'p1',
        ),
      ).called(1);
      expect(_ready(cubit).viewerTrend.last.ratingAfter, 1040);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'fetches the trend on its own when the viewer arrives after the load',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      stubTrend([_point(1010), _point(1040)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setViewer('p1');
    },
    verify: (cubit) {
      expect(_ready(cubit).viewerTrend, hasLength(2));
      expect(_ready(cubit).leaderboards, hasLength(1));
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'fetches the trend when the viewer arrives while the load is in flight',
    setUp: () {
      stubSeason();
      pendingLeaderboards = Completer<List<Leaderboard>>();
      when(
        () =>
            repository.leaderboards(competitionId: 'c1', seasonId: 's-august'),
      ).thenAnswer((_) => pendingLeaderboards.future);
      stubTrend([_point(1010), _point(1040)]);
    },
    build: build,
    act: (cubit) async {
      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);
      await cubit.setViewer('p1');
      pendingLeaderboards.complete([_leaderboard('p1', 1040, 1)]);
      await loading;
    },
    verify: (cubit) {
      expect(_ready(cubit).viewerTrend, hasLength(2));
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'asks for no trend before the season has a row',
    setUp: () {
      stubSeason(id: null);
      stubLeaderboards(null, const []);
    },
    build: build,
    act: (cubit) async {
      await cubit.setViewer('p1');
      await cubit.load();
    },
    verify: (cubit) {
      verifyNever(
        () => profileRepository.ratingHistory(
          seasonId: any(named: 'seasonId'),
          playerId: any(named: 'playerId'),
        ),
      );
      expect(_ready(cubit).viewerTrend, isEmpty);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'keeps the leaderboard when only the trend fetch fails',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      when(
        () => profileRepository.ratingHistory(
          seasonId: any(named: 'seasonId'),
          playerId: any(named: 'playerId'),
        ),
      ).thenThrow(const NetworkFailure());
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.setViewer('p1');
    },
    verify: (cubit) {
      expect(_ready(cubit).leaderboards, hasLength(1));
      expect(_ready(cubit).viewerTrend, isEmpty);
    },
  );
}
