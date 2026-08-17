import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/profile/domain/best_streaks.model.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/profile_stats.model.dart';
import 'package:keepscore2/features/profile/domain/rating_point.model.dart';
import 'package:keepscore2/features/profile/domain/recent_played.model.dart';
import 'package:keepscore2/features/profile/domain/streak.model.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_overview_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockLeaderboardRepository leaderboardRepository;
  late MockProfileRepository profileRepository;
  late MockMatchRepository matchRepository;
  late GameTypeFilterCubit gameTypeFilterCubit;

  ProfileOverviewCubit build() => ProfileOverviewCubit(
    leaderboardRepository,
    profileRepository,
    matchRepository,
    gameTypeFilterCubit,
    'c1',
    'p1',
  );

  void stubGameType(
    GameType? type, {
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
        gameType: type,
      ),
    ).thenAnswer((_) async => leaderboards);
    when(
      () => leaderboardRepository.medals('c1', gameType: type),
    ).thenAnswer((_) async => medals);
    when(
      () => profileRepository.ratingHistory(
        seasonId: 's-august',
        playerId: 'p1',
        gameType: type,
      ),
    ).thenAnswer((_) async => history);
    when(
      () => profileRepository.profileStats(
        playerId: 'p1',
        seasonId: any(named: 'seasonId'),
        gameType: type,
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
      () => matchRepository.recentForPlayer(playerId: 'p1', gameType: type),
    ).thenAnswer((_) async => recentMatches);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    leaderboardRepository = MockLeaderboardRepository();
    profileRepository = MockProfileRepository();
    matchRepository = MockMatchRepository();
    gameTypeFilterCubit = GameTypeFilterCubit();
    stubGameType(null);
  });

  tearDown(() => gameTypeFilterCubit.close());

  void stubSeason({String? id = 's-august'}) {
    when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(id: id, startsAt: _august, endsAt: _september),
    );
  }

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'loads the combined leaderboard, rating history, streak and recent matches',
    setUp: () {
      stubSeason();
      stubGameType(
        null,
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
      expect(state.selectedGameType, isNull);
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
      stubGameType(
        null,
        leaderboards: [_leaderboard('p1', 1000, 1)],
        bestRating: 1120,
      );
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
      stubGameType(null, leaderboards: [_leaderboard('p2', 960, 1)]);
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
      stubGameType(null, totalPlayed: 7);
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
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
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
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
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
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
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

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'selecting a game type refetches rank, rating, history, streak, totals, '
    'medals and recent matches for it, and hasOpponent survives the switch',
    setUp: () {
      stubSeason();
      stubGameType(
        null,
        leaderboards: [_leaderboard('p1', 1040, 1)],
        totalPlayed: 12,
        medals: const [Medals(playerId: 'p1', gold: 1, silver: 0, bronze: 0)],
      );
      stubGameType(
        GameType.oneVOne,
        leaderboards: [
          _leaderboard('p1', 1090, 1, played: 4, wins: 3, losses: 1),
        ],
        history: [
          RatingPoint(playedAt: _august, ratingAfter: 1090, ratingDelta: 20),
        ],
        streak: const Streak(type: StreakType.win, count: 3),
        totalPlayed: 9,
        recentMatches: [_match('m3')],
        medals: const [Medals(playerId: 'p1', gold: 0, silver: 2, bronze: 1)],
        bestRating: 1150,
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load(viewerPlayerId: 'viewer');
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
    },
    expect: () => [
      isA<ProfileOverviewLoading>(),
      isA<ProfileOverviewReady>()
          .having((s) => s.selectedGameType, 'selectedGameType', isNull)
          .having((s) => s.leaderboard?.rating, 'rating', 1040)
          .having((s) => s.medals?.gold, 'medals.gold', 1)
          .having((s) => s.hasOpponent, 'hasOpponent', isTrue),
      isA<ProfileOverviewReady>()
          .having(
            (s) => s.selectedGameType,
            'selectedGameType',
            GameType.oneVOne,
          )
          .having((s) => s.leaderboard?.rating, 'rating', 1090)
          .having((s) => s.leaderboard?.played, 'played', 4)
          .having((s) => s.bestRating, 'bestRating', 1150)
          .having((s) => s.totalPlayed, 'totalPlayed', 9)
          .having((s) => s.streak.count, 'streak.count', 3)
          .having((s) => s.recentMatches, 'recentMatches', hasLength(1))
          .having((s) => s.medals?.silver, 'medals.silver', 2)
          .having((s) => s.hasOpponent, 'hasOpponent', isTrue),
    ],
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'a player with no medals for the selected game type has none, even '
    'though they have some in another type',
    setUp: () {
      stubSeason();
      stubGameType(
        null,
        leaderboards: [_leaderboard('p1', 1040, 1)],
        medals: const [Medals(playerId: 'p1', gold: 1, silver: 0, bronze: 0)],
      );
      stubGameType(
        GameType.oneVOne,
        leaderboards: [_leaderboard('p1', 1090, 1)],
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) =>
        expect((cubit.state as ProfileOverviewReady).medals, isNull),
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'reselecting the same game type is a no-op',
    setUp: () {
      stubSeason();
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(null);
      await _settle();
    },
    expect: () => [isA<ProfileOverviewState>(), isA<ProfileOverviewState>()],
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'a slower response for an abandoned game type does not clobber a '
    'faster one for the type selected after it',
    setUp: () {
      stubSeason();
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
    },
    build: build,
    act: (cubit) async {
      await cubit.load();

      stubGameType(
        GameType.oneVOne,
        leaderboards: [_leaderboard('p1', 1090, 1)],
        medals: const [Medals(playerId: 'p1', gold: 2, silver: 0, bronze: 0)],
      );
      final slowLeaderboards = Completer<List<Leaderboard>>();
      when(
        () => leaderboardRepository.leaderboards(
          competitionId: 'c1',
          seasonId: 's-august',
          gameType: GameType.oneVOne,
        ),
      ).thenAnswer((_) => slowLeaderboards.future);
      stubGameType(
        GameType.twoVTwo,
        leaderboards: [_leaderboard('p1', 1010, 1)],
        medals: const [Medals(playerId: 'p1', gold: 1, silver: 0, bronze: 0)],
      );

      unawaited(cubit.selectGameTypeFilter(GameType.oneVOne));
      await _settle();
      await cubit.selectGameTypeFilter(GameType.twoVTwo);
      await _settle();

      slowLeaderboards.complete([_leaderboard('p1', 1090, 1)]);
      await _settle();
    },
    verify: (cubit) {
      final state = cubit.state as ProfileOverviewReady;
      expect(state.selectedGameType, GameType.twoVTwo);
      expect(state.leaderboard?.rating, 1010);
      expect(state.medals?.gold, 1);
    },
  );

  blocTest<ProfileOverviewCubit, ProfileOverviewState>(
    'a game type selected elsewhere (e.g. on the leaderboard) is picked up immediately',
    setUp: () {
      stubSeason();
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
      stubGameType(
        GameType.oneVOne,
        leaderboards: [
          _leaderboard('p1', 1090, 1, played: 4, wins: 3, losses: 1),
        ],
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await gameTypeFilterCubit.select(GameType.oneVOne);
      await _settle();
    },
    verify: (cubit) {
      final state = cubit.state as ProfileOverviewReady;
      expect(state.selectedGameType, GameType.oneVOne);
      expect(state.leaderboard?.rating, 1090);
    },
  );
}
