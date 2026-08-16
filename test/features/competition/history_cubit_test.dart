import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/presentation/cubit/history_cubit.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_leaderboard.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _june = DateTime.utc(2026, 5, 31, 22);
final _july = DateTime.utc(2026, 6, 30, 22);

Season _season(String id, DateTime startsAt) => Season(
  id: id,
  startsAt: startsAt,
  endsAt: startsAt.add(const Duration(days: 30)),
);

SeasonLeaderboard _leaderboard({
  required String seasonId,
  required DateTime startsAt,
  required String playerId,
  required int rank,
}) => SeasonLeaderboard(
  seasonId: seasonId,
  competitionId: 'c1',
  playerId: playerId,
  displayName: playerId,
  isClaimed: true,
  rating: 1000,
  played: 5,
  wins: 3,
  losses: 2,
  draws: 0,
  rank: rank,
  startsAt: startsAt,
  endsAt: startsAt.add(const Duration(days: 30)),
  medal: null,
);

void main() {
  late MockLeaderboardRepository repository;

  HistoryCubit build() => HistoryCubit(repository, 'c1');

  setUp(() {
    repository = MockLeaderboardRepository();
  });

  void stubSeasons(List<Season> seasons) {
    when(
      () => repository.finishedSeasons('c1'),
    ).thenAnswer((_) async => seasons);
  }

  void stubLeaderboards(
    String seasonId,
    List<SeasonLeaderboard> leaderboards, {
    GameType? gameType,
  }) {
    when(
      () => repository.history(
        competitionId: 'c1',
        seasonId: seasonId,
        gameType: gameType,
      ),
    ).thenAnswer((_) async => leaderboards);
  }

  blocTest<HistoryCubit, HistoryState>(
    'fetches just the season list up front, then only the newest season\'s '
    'leaderboard — not every season\'s',
    setUp: () {
      stubSeasons([_season('s-july', _july), _season('s-june', _june)]);
      stubLeaderboards('s-july', [
        _leaderboard(
          seasonId: 's-july',
          startsAt: _july,
          playerId: 'p2',
          rank: 1,
        ),
      ]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, HistoryStatus.ready);
      expect(cubit.state.seasons, hasLength(2));
      expect(cubit.state.seasons.first.id, 's-july');
      expect(cubit.state.selectedSeasonId, 's-july');
      expect(cubit.state.leaderboards.single.playerId, 'p2');
      verifyNever(
        () => repository.history(competitionId: 'c1', seasonId: 's-june'),
      );
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'selectSeason fetches that season\'s leaderboard, keyed by rank order',
    setUp: () {
      stubSeasons([_season('s-july', _july), _season('s-june', _june)]);
      stubLeaderboards('s-july', [
        _leaderboard(
          seasonId: 's-july',
          startsAt: _july,
          playerId: 'p2',
          rank: 1,
        ),
      ]);
      stubLeaderboards('s-june', [
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p1',
          rank: 1,
        ),
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p2',
          rank: 2,
        ),
      ]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectSeason('s-june');
    },
    verify: (cubit) {
      expect(cubit.state.selectedSeasonId, 's-june');
      expect(cubit.state.leaderboards.map((s) => s.playerId), ['p1', 'p2']);
      verify(
        () => repository.history(competitionId: 'c1', seasonId: 's-june'),
      ).called(1);
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'a season with nothing played for the selected game type shows an empty '
    'leaderboard — the season list itself does not change with the filter',
    setUp: () {
      stubSeasons([_season('s-july', _july), _season('s-june', _june)]);
      stubLeaderboards('s-july', [
        _leaderboard(
          seasonId: 's-july',
          startsAt: _july,
          playerId: 'p2',
          rank: 1,
        ),
      ]);
      stubLeaderboards('s-june', [
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p1',
          rank: 1,
        ),
      ]);
      stubLeaderboards('s-june', const [], gameType: GameType.oneVOne);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectSeason('s-june');
      await cubit.selectGameTypeFilter(GameType.oneVOne);
    },
    verify: (cubit) {
      expect(cubit.state.seasons, hasLength(2));
      expect(cubit.state.selectedSeasonId, 's-june');
      expect(cubit.state.leaderboards, isEmpty);
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'no closed seasons yet is ready with nothing to select',
    setUp: () => stubSeasons(const []),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, HistoryStatus.ready);
      expect(cubit.state.seasons, isEmpty);
      expect(cubit.state.selectedSeasonId, isNull);
      expect(cubit.state.leaderboards, isEmpty);
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () => repository.finishedSeasons('c1'),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, HistoryStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'filtering by game type refetches the selected season\'s leaderboard for it',
    setUp: () {
      stubSeasons([_season('s-june', _june)]);
      stubLeaderboards('s-june', [
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p1',
          rank: 1,
        ),
      ]);
      stubLeaderboards('s-june', [
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p2',
          rank: 1,
        ),
      ], gameType: GameType.oneVOne);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, GameType.oneVOne);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.leaderboards.single.playerId, 'p2');
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'clearing the game type filter goes back to combined history',
    setUp: () {
      stubSeasons([_season('s-june', _june)]);
      stubLeaderboards('s-june', [
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p1',
          rank: 1,
        ),
      ]);
      stubLeaderboards('s-june', [
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p2',
          rank: 1,
        ),
      ], gameType: GameType.oneVOne);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await cubit.selectGameTypeFilter(null);
    },
    verify: (cubit) {
      expect(cubit.state.selectedGameType, isNull);
      expect(cubit.state.leaderboards.single.playerId, 'p1');
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'reselecting the same season is a no-op',
    setUp: () {
      stubSeasons([_season('s-june', _june)]);
      stubLeaderboards('s-june', [
        _leaderboard(
          seasonId: 's-june',
          startsAt: _june,
          playerId: 'p1',
          rank: 1,
        ),
      ]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectSeason('s-june');
    },
    verify: (cubit) => verify(
      () => repository.history(competitionId: 'c1', seasonId: 's-june'),
    ).called(1),
  );
}
