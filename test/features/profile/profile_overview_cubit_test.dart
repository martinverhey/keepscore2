import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/profile/domain/best_streaks.model.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/profile_stats.model.dart';
import 'package:keepscore2/features/profile/domain/rating_point.model.dart';
import 'package:keepscore2/features/profile/domain/recent_played.model.dart';
import 'package:keepscore2/features/profile/domain/streak.model.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_overview_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

Leaderboard _leaderboard(
  String playerId,
  double rating,
  int rank, {
  int played = 3,
  int wins = 2,
  int losses = 1,
  int draws = 0,
}) => Leaderboard(
  seasonId: 's-august',
  competitionId: 'c1',
  playerId: playerId,
  displayName: playerId,
  isClaimed: true,
  isOwner: false,
  rating: rating,
  played: played,
  wins: wins,
  losses: losses,
  draws: draws,
  rank: rank,
);

MatchEntry _match(String id) => MatchEntry(
  id: id,
  competitionId: 'c1',
  seasonId: 's-august',
  playedAt: _august,
  teamAScore: 3,
  teamBScore: 1,
  teamARating: 1040,
  teamBRating: 960,
  teamA: const [],
  teamB: const [],
);

void main() {
  late MockLeaderboardRepository leaderboardRepository;
  late MockProfileRepository profileRepository;
  late MockMatchRepository matchRepository;

  ProfileOverviewCubit build() => ProfileOverviewCubit(
    leaderboardRepository,
    profileRepository,
    matchRepository,
    'c1',
    'p1',
  );

  void stub({
    List<Leaderboard> leaderboards = const [],
    List<RatingPoint> history = const [],
    Streak streak = const Streak.none(),
    BestStreaks bestStreaks = const BestStreaks.zero(),
    RecentPlayed recentPlayed = const RecentPlayed.zero(),
    int totalPlayed = 0,
    List<MatchEntry> recentMatches = const [],
    List<Medals> medals = const [],
    double bestRating = 0,
  }) {
    when(
      () => leaderboardRepository.leaderboards(
        competitionId: 'c1',
        seasonId: 's-august',
      ),
    ).thenAnswer((_) async => leaderboards);
    when(
      () => leaderboardRepository.medals('c1'),
    ).thenAnswer((_) async => medals);
    when(
      () =>
          profileRepository.ratingHistory(seasonId: 's-august', playerId: 'p1'),
    ).thenAnswer((_) async => history);
    when(
      () => profileRepository.profileStats(
        playerId: 'p1',
        seasonId: any(named: 'seasonId'),
      ),
    ).thenAnswer(
      (_) async => ProfileStats(
        totalPlayed: totalPlayed,
        bestStreaks: bestStreaks,
        bestRating: bestRating,
        streak: streak,
        recentPlayed: recentPlayed,
      ),
    );
    when(
      () => matchRepository.recentForPlayer(playerId: 'p1'),
    ).thenAnswer((_) async => recentMatches);
  }

  setUp(() {
    leaderboardRepository = MockLeaderboardRepository();
    profileRepository = MockProfileRepository();
    matchRepository = MockMatchRepository();
    stub();
  });

  void stubSeason({String? id = 's-august'}) {
    when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(id: id, startsAt: _august, endsAt: _september),
    );
  }

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'loads the combined leaderboard, rating history, streak and recent matches',
    setUp: () {
      stubSeason();
      stub(
        leaderboards: [_leaderboard('p1', 1040, 1), _leaderboard('p2', 960, 2)],
        history: [
          RatingPoint(playedAt: _august, ratingAfter: 1010, ratingDelta: 10),
          RatingPoint(playedAt: _august, ratingAfter: 1040, ratingDelta: 30),
        ],
        streak: const Streak(type: StreakType.win, count: 2),
        totalPlayed: 12,
        recentMatches: [_match('m1'), _match('m2')],
      );
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as ProfileOverviewReady;
      expect(state.leaderboard?.playerId, 'p1');
      expect(state.playerCount, 2);
      expect(state.history, hasLength(2));
      expect(state.totalPlayed, 12);
      expect(state.streak.type, StreakType.win);
      expect(state.streak.count, 2);
      expect(state.recentMatches, hasLength(2));
    },
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'the best rating comes straight off the all-time scalar, not the season list',
    setUp: () {
      stubSeason();
      stub(leaderboards: [_leaderboard('p1', 1000, 1)], bestRating: 1120);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as ProfileOverviewReady;
      expect(state.leaderboard?.rating, 1000);
      expect(state.bestRating, 1120);
    },
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'a season with no matches yet is ready with no leaderboard, history or streak',
    setUp: () => stubSeason(id: null),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as ProfileOverviewReady;
      expect(state.leaderboard, isNull);
      expect(state.history, isEmpty);
      expect(state.streak.type, StreakType.none);
    },
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'a player missing from the leaderboards (not yet played) has no leaderboard',
    setUp: () {
      stubSeason();
      stub(leaderboards: [_leaderboard('p2', 960, 1)]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as ProfileOverviewReady;
      expect(state.leaderboard, isNull);
      expect(state.playerCount, 1);
    },
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'always loads total matches played, even with no current-season matches',
    setUp: () {
      stubSeason(id: null);
      stub(totalPlayed: 7);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) =>
        expect((cubit.state as ProfileOverviewReady).totalPlayed, 7),
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'flags an opponent when viewing someone else, keyed off the viewer',
    setUp: () {
      stubSeason();
      stub(leaderboards: [_leaderboard('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) => cubit.load(viewerPlayerId: 'viewer'),
    verify: (cubit) =>
        expect((cubit.state as ProfileOverviewReady).hasOpponent, isTrue),
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'there is no opponent when viewing your own profile',
    setUp: () {
      stubSeason();
      stub(leaderboards: [_leaderboard('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) => cubit.load(viewerPlayerId: 'p1'),
    verify: (cubit) =>
        expect((cubit.state as ProfileOverviewReady).hasOpponent, isFalse),
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'there is also no opponent when the viewer is unknown',
    setUp: () {
      stubSeason();
      stub(leaderboards: [_leaderboard('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) =>
        expect((cubit.state as ProfileOverviewReady).hasOpponent, isFalse),
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'a failed load surfaces the error',
    setUp: () => when(
      () => leaderboardRepository.currentSeason('c1'),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(
        (cubit.state as ProfileOverviewFailed).failure,
        isA<NetworkFailure>(),
      );
    },
  );
}
