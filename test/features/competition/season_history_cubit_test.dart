import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/presentation/cubit/season_history_cubit.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_standing.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _june = DateTime.utc(2026, 5, 31, 22);
final _july = DateTime.utc(2026, 6, 30, 22);

Season _season(String id, DateTime startsAt) =>
    Season(id: id, startsAt: startsAt, endsAt: startsAt.add(const Duration(days: 30)));

SeasonStanding _standing({
  required String seasonId,
  required DateTime startsAt,
  required String playerId,
  required int rank,
}) => SeasonStanding(
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

  SeasonHistoryCubit build() => SeasonHistoryCubit(repository, 'c1');

  setUp(() {
    repository = MockLeaderboardRepository();
  });

  void stubSeasons(List<Season> seasons) {
    when(
      () => repository.finishedSeasons('c1'),
    ).thenAnswer((_) async => seasons);
  }

  void stubStandings(
    String seasonId,
    List<SeasonStanding> standings, {
    GameType? gameType,
  }) {
    when(
      () => repository.seasonHistory(
        competitionId: 'c1',
        seasonId: seasonId,
        gameType: gameType,
      ),
    ).thenAnswer((_) async => standings);
  }

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'fetches just the season list up front, then only the newest season\'s '
    'standings — not every season\'s',
    setUp: () {
      stubSeasons([_season('s-july', _july), _season('s-june', _june)]);
      stubStandings('s-july', [
        _standing(seasonId: 's-july', startsAt: _july, playerId: 'p2', rank: 1),
      ]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, SeasonHistoryStatus.ready);
      expect(cubit.state.seasons, hasLength(2));
      expect(cubit.state.seasons.first.id, 's-july');
      expect(cubit.state.selectedSeasonId, 's-july');
      expect(cubit.state.standings.single.playerId, 'p2');
      verifyNever(
        () => repository.seasonHistory(
          competitionId: 'c1',
          seasonId: 's-june',
        ),
      );
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'selectSeason fetches that season\'s standings, keyed by rank order',
    setUp: () {
      stubSeasons([_season('s-july', _july), _season('s-june', _june)]);
      stubStandings('s-july', [
        _standing(seasonId: 's-july', startsAt: _july, playerId: 'p2', rank: 1),
      ]);
      stubStandings('s-june', [
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p1', rank: 1),
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p2', rank: 2),
      ]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectSeason('s-june');
    },
    verify: (cubit) {
      expect(cubit.state.selectedSeasonId, 's-june');
      expect(cubit.state.standings.map((s) => s.playerId), ['p1', 'p2']);
      verify(
        () => repository.seasonHistory(competitionId: 'c1', seasonId: 's-june'),
      ).called(1);
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'a season with nothing played for the selected game type shows empty '
    'standings — the season list itself does not change with the filter',
    setUp: () {
      stubSeasons([_season('s-july', _july), _season('s-june', _june)]);
      stubStandings('s-july', [
        _standing(seasonId: 's-july', startsAt: _july, playerId: 'p2', rank: 1),
      ]);
      stubStandings('s-june', [
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p1', rank: 1),
      ]);
      stubStandings('s-june', const [], gameType: GameType.oneVOne);
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
      expect(cubit.state.standings, isEmpty);
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'no closed seasons yet is ready with nothing to select',
    setUp: () => stubSeasons(const []),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, SeasonHistoryStatus.ready);
      expect(cubit.state.seasons, isEmpty);
      expect(cubit.state.selectedSeasonId, isNull);
      expect(cubit.state.standings, isEmpty);
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'a failed load surfaces the error',
    setUp: () =>
        when(() => repository.finishedSeasons('c1')).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, SeasonHistoryStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'filtering by game type refetches the selected season\'s standings for it',
    setUp: () {
      stubSeasons([_season('s-june', _june)]);
      stubStandings('s-june', [
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p1', rank: 1),
      ]);
      stubStandings('s-june', [
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p2', rank: 1),
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
      expect(cubit.state.standings.single.playerId, 'p2');
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'clearing the game type filter goes back to combined history',
    setUp: () {
      stubSeasons([_season('s-june', _june)]);
      stubStandings('s-june', [
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p1', rank: 1),
      ]);
      stubStandings('s-june', [
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p2', rank: 1),
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
      expect(cubit.state.standings.single.playerId, 'p1');
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'reselecting the same season is a no-op',
    setUp: () {
      stubSeasons([_season('s-june', _june)]);
      stubStandings('s-june', [
        _standing(seasonId: 's-june', startsAt: _june, playerId: 'p1', rank: 1),
      ]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectSeason('s-june');
    },
    verify: (cubit) => verify(
      () => repository.seasonHistory(competitionId: 'c1', seasonId: 's-june'),
    ).called(1),
  );
}
