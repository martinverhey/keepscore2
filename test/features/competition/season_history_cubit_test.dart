import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/presentation/cubit/season_history_cubit.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_standing.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

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

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'groups standings by season, newest first, keeping rank order within a season',
    setUp: () => when(
      () => repository.seasonHistory(competitionId: 'c1'),
    ).thenAnswer(
      (_) async => [
        _standing(
          seasonId: 's-june',
          startsAt: DateTime.utc(2026, 5, 31, 22),
          playerId: 'p1',
          rank: 1,
        ),
        _standing(
          seasonId: 's-june',
          startsAt: DateTime.utc(2026, 5, 31, 22),
          playerId: 'p2',
          rank: 2,
        ),
        _standing(
          seasonId: 's-july',
          startsAt: DateTime.utc(2026, 6, 30, 22),
          playerId: 'p2',
          rank: 1,
        ),
      ],
    ),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, SeasonHistoryStatus.ready);
      expect(cubit.state.groups, hasLength(2));
      expect(cubit.state.groups.first.seasonId, 's-july');
      expect(cubit.state.groups.last.seasonId, 's-june');
      expect(
        cubit.state.groups.last.standings.map((s) => s.playerId),
        ['p1', 'p2'],
      );
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'no closed seasons yet is ready with no groups',
    setUp: () => when(
      () => repository.seasonHistory(competitionId: 'c1'),
    ).thenAnswer((_) async => const []),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, SeasonHistoryStatus.ready);
      expect(cubit.state.groups, isEmpty);
    },
  );

  blocTest<SeasonHistoryCubit, SeasonHistoryState>(
    'a failed load surfaces the error',
    setUp: () => when(() => repository.seasonHistory(competitionId: 'c1'))
        .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, SeasonHistoryStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );
}
