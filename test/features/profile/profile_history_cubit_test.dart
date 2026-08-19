import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_leaderboard.model.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_history_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final _july = DateTime.utc(2026, 6, 30, 22);
final _august = DateTime.utc(2026, 7, 31, 22);

SeasonLeaderboard _pastSeason(double rating) => SeasonLeaderboard(
  seasonId: 's-july',
  competitionId: 'c1',
  playerId: 'p1',
  displayName: 'p1',
  isClaimed: true,
  rating: rating,
  played: 5,
  wins: 4,
  losses: 1,
  draws: 0,
  rank: 1,
  startsAt: _july,
  endsAt: _august,
  medal: null,
);

void main() {
  late MockLeaderboardRepository leaderboardRepository;

  ProfileHistoryCubit build() =>
      ProfileHistoryCubit(leaderboardRepository, 'c1', 'p1');

  setUp(() {
    leaderboardRepository = MockLeaderboardRepository();
  });

  blocTest<ProfileHistoryCubit, ProfileHistoryState>(
    'loads this player\'s leaderboard entry in every finished season',
    setUp: () => when(
      () => leaderboardRepository.history(competitionId: 'c1', playerId: 'p1'),
    ).thenAnswer((_) async => [_pastSeason(1120)]),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as ProfileHistoryReady;
      expect(state.leaderboards, hasLength(1));
      expect(state.leaderboards.single.rating, 1120);
    },
  );

  blocTest<ProfileHistoryCubit, ProfileHistoryState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () => leaderboardRepository.history(competitionId: 'c1', playerId: 'p1'),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(
        (cubit.state as ProfileHistoryFailed).failure,
        isA<NetworkFailure>(),
      );
    },
  );
}
