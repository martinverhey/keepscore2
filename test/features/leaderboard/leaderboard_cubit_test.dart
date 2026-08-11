import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);
final _july = DateTime.utc(2026, 6, 30, 22);

Leaderboard _standing(String playerId, double rating, int rank) => Leaderboard(
  seasonId: 's-august',
  competitionId: 'c1',
  playerId: playerId,
  displayName: playerId,
  isClaimed: true,
  rating: rating,
  played: 3,
  wins: 2,
  losses: 1,
  draws: 0,
  rank: rank,
);

void main() {
  late MockLeaderboardRepository repository;
  late StreamController<void> ticks;

  LeaderboardCubit build() => LeaderboardCubit(repository, 'c1');

  void stubSeason({String? id = 's-august', List<Season> stored = const []}) {
    when(() => repository.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(id: id, startsAt: _august, endsAt: _september),
    );
    when(() => repository.seasons('c1')).thenAnswer((_) async => stored);
  }

  void stubStandings(String? seasonId, List<Leaderboard> standings) {
    when(
      () => repository.standings(competitionId: 'c1', seasonId: seasonId),
    ).thenAnswer((_) async => standings);
  }

  setUp(() {
    repository = MockLeaderboardRepository();
    ticks = StreamController<void>.broadcast();
    when(
      () => repository.watchStandings(
        competitionId: any(named: 'competitionId'),
        seasonId: any(named: 'seasonId'),
      ),
    ).thenAnswer((_) => ticks.stream);
  });

  tearDown(() => ticks.close());

  blocTest<LeaderboardCubit, LeaderboardState>(
    'loads the current season and its standings',
    setUp: () {
      stubSeason(
        stored: [
          Season(id: 's-august', startsAt: _august, endsAt: _september),
          Season(id: 's-july', startsAt: _july, endsAt: _august),
        ],
      );
      stubStandings('s-august', [
        _standing('p1', 1040, 1),
        _standing('p2', 960, 2),
      ]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, LeaderboardStatus.ready);
      expect(cubit.state.seasons, hasLength(2));
      expect(cubit.state.isShowingCurrentSeason, isTrue);
      expect(cubit.state.hasHistory, isTrue);
      expect(cubit.state.standings.first.playerId, 'p1');
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a season nobody has played yet is still offered, with no standings',
    setUp: () {
      stubSeason(
        id: null,
        stored: [Season(id: 's-july', startsAt: _july, endsAt: _august)],
      );
      stubStandings(null, const []);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.seasons.first.startsAt.isAtSameMomentAs(_august), isTrue);
      expect(cubit.state.seasons.first.hasStarted, isFalse);
      expect(cubit.state.isShowingCurrentSeason, isTrue);
      expect(cubit.state.standings, isEmpty);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'switching season fetches that season and keeps the choice on refresh',
    setUp: () {
      stubSeason(
        stored: [
          Season(id: 's-august', startsAt: _august, endsAt: _september),
          Season(id: 's-july', startsAt: _july, endsAt: _august),
        ],
      );
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
      stubStandings('s-july', [_standing('p2', 1100, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectSeason(_july);
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state.isShowingCurrentSeason, isFalse);
      expect(cubit.state.standings.single.playerId, 'p2');
      expect(cubit.state.busy, isFalse);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a rating written by someone else arrives without a gesture',
    setUp: () {
      stubSeason(
        stored: [Season(id: 's-august', startsAt: _august, endsAt: _september)],
      );
      stubStandings('s-august', [_standing('p1', 1000, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      stubStandings('s-august', [
        _standing('p1', 1032, 1),
        _standing('p2', 968, 2),
      ]);
      ticks.add(null);
    },
    wait: const Duration(milliseconds: 600),
    verify: (cubit) {
      expect(cubit.state.standings, hasLength(2));
      expect(cubit.state.standings.first.rating, 1032);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'the subscription follows the selected season',
    setUp: () {
      stubSeason(
        stored: [
          Season(id: 's-august', startsAt: _august, endsAt: _september),
          Season(id: 's-july', startsAt: _july, endsAt: _august),
        ],
      );
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
      stubStandings('s-july', [_standing('p2', 1100, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectSeason(_july);
      await cubit.refresh();
    },
    verify: (cubit) {
      verify(
        () => repository.watchStandings(
          competitionId: 'c1',
          seasonId: 's-august',
        ),
      ).called(1);
      verify(
        () =>
            repository.watchStandings(competitionId: 'c1', seasonId: 's-july'),
      ).called(1);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a failed silent refresh keeps the table on screen',
    setUp: () {
      stubSeason(
        stored: [Season(id: 's-august', startsAt: _august, endsAt: _september)],
      );
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(() => repository.seasons('c1')).thenThrow(const NetworkFailure());
      await cubit.refresh();
    },
    verify: (cubit) {
      expect(cubit.state.status, LeaderboardStatus.failed);
      expect(cubit.state.standings, hasLength(1));
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );
}
