import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.dart';
import 'package:keepscore2/features/leaderboard/domain/standing.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/rating_point.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

Standing _standing(String playerId, double rating, int rank) => Standing(
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
  late MockLeaderboardRepository leaderboardRepository;
  late MockProfileRepository profileRepository;

  ProfileCubit build() =>
      ProfileCubit(leaderboardRepository, profileRepository, 'c1', 'p1');

  setUp(() {
    leaderboardRepository = MockLeaderboardRepository();
    profileRepository = MockProfileRepository();
  });

  void stubSeason({String? id = 's-august'}) {
    when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(id: id, startsAt: _august, endsAt: _september),
    );
  }

  blocTest<ProfileCubit, ProfileState>(
    'loads the standing for this player and the rating history',
    setUp: () {
      stubSeason();
      when(
        () => leaderboardRepository.standings(
          competitionId: 'c1',
          seasonId: 's-august',
        ),
      ).thenAnswer(
        (_) async => [_standing('p1', 1040, 1), _standing('p2', 960, 2)],
      );
      when(
        () => profileRepository.ratingHistory(
          seasonId: 's-august',
          playerId: 'p1',
        ),
      ).thenAnswer(
        (_) async => [
          RatingPoint(playedAt: _august, ratingAfter: 1010, ratingDelta: 10),
          RatingPoint(playedAt: _august, ratingAfter: 1040, ratingDelta: 30),
        ],
      );
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.standing?.playerId, 'p1');
      expect(cubit.state.playerCount, 2);
      expect(cubit.state.history, hasLength(2));
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'a season with no matches yet is ready with no standing or history',
    setUp: () => stubSeason(id: null),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.standing, isNull);
      expect(cubit.state.history, isEmpty);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'a player missing from the standings (not yet played) has no standing',
    setUp: () {
      stubSeason();
      when(
        () => leaderboardRepository.standings(
          competitionId: 'c1',
          seasonId: 's-august',
        ),
      ).thenAnswer((_) async => [_standing('p2', 960, 1)]);
      when(
        () => profileRepository.ratingHistory(
          seasonId: 's-august',
          playerId: 'p1',
        ),
      ).thenAnswer((_) async => const []);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.standing, isNull);
      expect(cubit.state.playerCount, 1);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'a failed load surfaces the error',
    setUp: () => when(() => leaderboardRepository.currentSeason('c1'))
        .thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );
}
