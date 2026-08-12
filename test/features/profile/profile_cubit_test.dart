import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_standing.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.dart';
import 'package:keepscore2/features/match/domain/game_type.dart';
import 'package:keepscore2/features/profile/domain/head_to_head_record.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/rating_point.dart';
import 'package:keepscore2/features/profile/domain/streak.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

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
  late MockLeaderboardRepository leaderboardRepository;
  late MockProfileRepository profileRepository;

  ProfileCubit build() =>
      ProfileCubit(leaderboardRepository, profileRepository, 'c1', 'p1');

  setUp(() {
    leaderboardRepository = MockLeaderboardRepository();
    profileRepository = MockProfileRepository();
    when(
      () => profileRepository.totalMatchesPlayed(playerId: 'p1'),
    ).thenAnswer((_) async => 0);
    when(
      () => leaderboardRepository.seasonHistory(
        competitionId: 'c1',
        playerId: 'p1',
      ),
    ).thenAnswer((_) async => const []);
  });

  void stubSeason({String? id = 's-august'}) {
    when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(id: id, startsAt: _august, endsAt: _september),
    );
  }

  void stubStreak(Streak streak) {
    when(
      () => profileRepository.currentStreak(
        seasonId: 's-august',
        playerId: 'p1',
      ),
    ).thenAnswer((_) async => streak);
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
      stubStreak(const Streak(type: StreakType.win, count: 2));
      when(
        () => profileRepository.totalMatchesPlayed(playerId: 'p1'),
      ).thenAnswer((_) async => 12);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.standing?.playerId, 'p1');
      expect(cubit.state.playerCount, 2);
      expect(cubit.state.history, hasLength(2));
      expect(cubit.state.totalPlayed, 12);
      expect(cubit.state.streak.type, StreakType.win);
      expect(cubit.state.streak.count, 2);
      expect(cubit.state.headToHead, isEmpty);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'a season with no matches yet is ready with no standing, history or streak',
    setUp: () => stubSeason(id: null),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.standing, isNull);
      expect(cubit.state.history, isEmpty);
      expect(cubit.state.streak.type, StreakType.none);
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
      stubStreak(const Streak.none());
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
    'always loads total matches played and season history, even with no current-season matches',
    setUp: () {
      stubSeason(id: null);
      when(
        () => profileRepository.totalMatchesPlayed(playerId: 'p1'),
      ).thenAnswer((_) async => 7);
      when(
        () => leaderboardRepository.seasonHistory(
          competitionId: 'c1',
          playerId: 'p1',
        ),
      ).thenAnswer(
        (_) async => [
          SeasonStanding(
            seasonId: 's-july',
            competitionId: 'c1',
            playerId: 'p1',
            displayName: 'p1',
            isClaimed: true,
            rating: 1080,
            played: 5,
            wins: 4,
            losses: 1,
            draws: 0,
            rank: 1,
            startsAt: DateTime.utc(2026, 6, 30, 22),
            endsAt: _august,
            medal: null,
          ),
        ],
      );
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.totalPlayed, 7);
      expect(cubit.state.seasonHistory, hasLength(1));
      expect(cubit.state.seasonHistory.single.seasonId, 's-july');
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'fetches head-to-head when viewing someone else, keyed off the viewer',
    setUp: () {
      stubSeason();
      when(
        () => leaderboardRepository.standings(
          competitionId: 'c1',
          seasonId: 's-august',
        ),
      ).thenAnswer((_) async => [_standing('p1', 1040, 1)]);
      when(
        () => profileRepository.ratingHistory(
          seasonId: 's-august',
          playerId: 'p1',
        ),
      ).thenAnswer((_) async => const []);
      stubStreak(const Streak.none());
      when(
        () => profileRepository.headToHead(
          playerId: 'p1',
          opponentId: 'viewer',
        ),
      ).thenAnswer(
        (_) async => const [
          HeadToHeadRecord(
            gameType: GameType.oneVOne,
            wins: 3,
            losses: 1,
            draws: 0,
          ),
        ],
      );
    },
    build: build,
    act: (cubit) => cubit.load(viewerPlayerId: 'viewer'),
    verify: (cubit) {
      expect(cubit.state.headToHead, hasLength(1));
      expect(cubit.state.headToHead.single.wins, 3);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'does not fetch head-to-head when viewing your own profile',
    setUp: () {
      stubSeason();
      when(
        () => leaderboardRepository.standings(
          competitionId: 'c1',
          seasonId: 's-august',
        ),
      ).thenAnswer((_) async => [_standing('p1', 1040, 1)]);
      when(
        () => profileRepository.ratingHistory(
          seasonId: 's-august',
          playerId: 'p1',
        ),
      ).thenAnswer((_) async => const []);
      stubStreak(const Streak.none());
    },
    build: build,
    act: (cubit) => cubit.load(viewerPlayerId: 'p1'),
    verify: (cubit) {
      expect(cubit.state.headToHead, isEmpty);
      verifyNever(
        () => profileRepository.headToHead(
          playerId: any(named: 'playerId'),
          opponentId: any(named: 'opponentId'),
        ),
      );
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
