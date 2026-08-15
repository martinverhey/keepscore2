import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/match/domain/game_type.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

Leaderboard _standing(String playerId, double rating, int rank) => Leaderboard(
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

  void stubStandings(String? seasonId, List<Leaderboard> standings) {
    when(
      () => repository.standings(competitionId: 'c1', seasonId: seasonId),
    ).thenAnswer((_) async => standings);
  }

  void stubGameTypeStandings(
    String? seasonId,
    GameType gameType,
    List<Leaderboard> standings,
  ) {
    when(
      () => repository.standings(
        competitionId: 'c1',
        seasonId: seasonId,
        gameType: gameType,
      ),
    ).thenAnswer((_) async => standings);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockLeaderboardRepository();
    gameTypeFilterCubit = GameTypeFilterCubit();
    ticks = StreamController<void>.broadcast();
    when(
      () => repository.watchStandings(
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
    'loads the current season and its standings',
    setUp: () {
      stubSeason();
      stubStandings('s-august', [
        _standing('p1', 1040, 1),
        _standing('p2', 960, 2),
      ]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, LeaderboardStatus.ready);
      expect(cubit.state.season?.id, 's-august');
      expect(cubit.state.standings.first.playerId, 'p1');
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'loads medal tallies alongside standings',
    setUp: () {
      stubSeason();
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
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
    'a season nobody has played yet is still offered, with no standings',
    setUp: () {
      stubSeason(id: null);
      stubStandings(null, const []);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.season!.startsAt.isAtSameMomentAs(_august), isTrue);
      expect(cubit.state.season!.hasStarted, isFalse);
      expect(cubit.state.standings, isEmpty);
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a rating written by someone else arrives without a gesture',
    setUp: () {
      stubSeason();
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
    'the subscription watches the current season',
    setUp: () {
      stubSeason();
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      verify(
        () => repository.watchStandings(
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
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
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
      expect(cubit.state.standings, hasLength(1));
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'filtering by game type fetches that game type\'s standings',
    setUp: () {
      stubSeason();
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
      stubGameTypeStandings('s-august', GameType.oneVOne, [
        _standing('p2', 1100, 1),
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
      expect(cubit.state.standings.single.playerId, 'p2');
      expect(cubit.state.busy, isFalse);
      verify(
        () => repository.watchStandings(
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
      stubGameTypeStandings('s-august', GameType.oneVOne, [
        _standing('p2', 1100, 1),
      ]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.oneVOne);
      expect(cubit.state.standings.single.playerId, 'p2');
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'clearing the game type filter goes back to combined standings',
    setUp: () {
      stubSeason();
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
      stubGameTypeStandings('s-august', GameType.oneVOne, [
        _standing('p2', 1100, 1),
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
      expect(cubit.state.standings.single.playerId, 'p1');
    },
  );

  blocTest<LeaderboardCubit, LeaderboardState>(
    'a game type selected elsewhere (e.g. on the profile page) is picked up immediately',
    setUp: () {
      stubSeason();
      stubStandings('s-august', [_standing('p1', 1040, 1)]);
      stubGameTypeStandings('s-august', GameType.oneVOne, [
        _standing('p2', 1100, 1),
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
      expect(cubit.state.standings.single.playerId, 'p2');
    },
  );
}
