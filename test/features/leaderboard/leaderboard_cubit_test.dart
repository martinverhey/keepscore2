import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

Leaderboard _leaderboard(String playerId, double rating, int rank) => Leaderboard(
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

void main() {
  late MockLeaderboardRepository repository;
  late GameTypeFilterCubit gameTypeFilterCubit;
  late StreamController<void> ticks;

  LeaderboardCubit build() =>
      LeaderboardCubit(repository, gameTypeFilterCubit, 'c1');

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

  void stubGameTypeLeaderboards(
    String? seasonId,
    GameType gameType,
    List<Leaderboard> leaderboards,
  ) {
    when(
      () => repository.leaderboards(
        competitionId: 'c1',
        seasonId: seasonId,
        gameType: gameType,
      ),
    ).thenAnswer((_) async => leaderboards);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockLeaderboardRepository();
    gameTypeFilterCubit = GameTypeFilterCubit();
    ticks = StreamController<void>.broadcast();
    when(
      () => repository.watchLeaderboards(
        competitionId: any(named: 'competitionId'),
        seasonId: any(named: 'seasonId'),
        gameType: any(named: 'gameType'),
      ),
    ).thenAnswer((_) => ticks.stream);
    when(() => repository.medals('c1')).thenAnswer((_) async => const []);
  });

  tearDown(() {
    ticks.close();
    gameTypeFilterCubit.close();
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
      expect(cubit.state.status, LeaderboardStatus.ready);
      expect(cubit.state.season?.id, 's-august');
      expect(cubit.state.leaderboards.first.playerId, 'p1');
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
      expect(cubit.state.medals['p1']?.gold, 2);
      expect(cubit.state.medals['p1']?.bronze, 1);
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
      expect(cubit.state.season!.startsAt.isAtSameMomentAs(_august), isTrue);
      expect(cubit.state.season!.hasStarted, isFalse);
      expect(cubit.state.leaderboards, isEmpty);
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
      expect(cubit.state.leaderboards, hasLength(2));
      expect(cubit.state.leaderboards.first.rating, 1032);
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
      expect(cubit.state.status, LeaderboardStatus.failed);
      expect(cubit.state.leaderboards, hasLength(1));
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'filtering by game type fetches that game type\'s leaderboards',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      stubGameTypeLeaderboards('s-august', GameType.oneVOne, [
        _leaderboard('p2', 1100, 1),
      ]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.oneVOne);
      expect(cubit.state.leaderboards.single.playerId, 'p2');
      expect(cubit.state.busy, isFalse);
      verify(
        () => repository.watchLeaderboards(
          competitionId: 'c1',
          seasonId: 's-august',
          gameType: GameType.oneVOne,
        ),
      ).called(1);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'loading hydrates the filter from the last remembered game type',
    setUp: () async {
      SharedPreferences.setMockInitialValues({'selected_game_type': '1v1'});
      await gameTypeFilterCubit.load();
      stubSeason();
      stubGameTypeLeaderboards('s-august', GameType.oneVOne, [
        _leaderboard('p2', 1100, 1),
      ]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.oneVOne);
      expect(cubit.state.leaderboards.single.playerId, 'p2');
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'clearing the game type filter goes back to combined leaderboards',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      stubGameTypeLeaderboards('s-august', GameType.oneVOne, [
        _leaderboard('p2', 1100, 1),
      ]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
      await cubit.selectGameTypeFilter(null);
      await _settle();
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, isNull);
      expect(cubit.state.leaderboards.single.playerId, 'p1');
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a game type selected elsewhere (e.g. on the profile page) is picked up immediately',
    setUp: () {
      stubSeason();
      stubLeaderboards('s-august', [_leaderboard('p1', 1040, 1)]);
      stubGameTypeLeaderboards('s-august', GameType.oneVOne, [
        _leaderboard('p2', 1100, 1),
      ]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await gameTypeFilterCubit.select(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.oneVOne);
      expect(cubit.state.leaderboards.single.playerId, 'p2');
    },
  );
}
