import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_standing.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/profile/domain/head_to_head_record.model.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/rating_point.model.dart';
import 'package:keepscore2/features/profile/domain/streak.model.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_cubit.dart';
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

SeasonStanding _pastSeason(double rating) => SeasonStanding(
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
  startsAt: DateTime.utc(2026, 6, 30, 22),
  endsAt: _august,
  medal: null,
);

void main() {
  late MockLeaderboardRepository leaderboardRepository;
  late MockProfileRepository profileRepository;
  late MockMatchRepository matchRepository;
  late GameTypeFilterCubit gameTypeFilterCubit;

  ProfileCubit build() => ProfileCubit(
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
    int totalPlayed = 0,
    List<MatchEntry> recentMatches = const [],
    List<SeasonStanding> seasonHistory = const [],
  }) {
    when(
      () => leaderboardRepository.leaderboards(
        competitionId: 'c1',
        seasonId: 's-august',
        gameType: type,
      ),
    ).thenAnswer((_) async => leaderboards);
    when(
      () => profileRepository.ratingHistory(
        seasonId: 's-august',
        playerId: 'p1',
        gameType: type,
      ),
    ).thenAnswer((_) async => history);
    when(
      () => profileRepository.currentStreak(
        seasonId: 's-august',
        playerId: 'p1',
        gameType: type,
      ),
    ).thenAnswer((_) async => streak);
    when(
      () =>
          profileRepository.totalMatchesPlayed(playerId: 'p1', gameType: type),
    ).thenAnswer((_) async => totalPlayed);
    when(
      () => matchRepository.recentForPlayer(playerId: 'p1', gameType: type),
    ).thenAnswer((_) async => recentMatches);
    when(
      () => leaderboardRepository.seasonHistory(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: type,
      ),
    ).thenAnswer((_) async => seasonHistory);
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

  blocTest<ProfileCubit, ProfileState>(
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
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.selectedGameType, isNull);
      expect(cubit.state.leaderboard?.playerId, 'p1');
      expect(cubit.state.bestRating, 1040);
      expect(cubit.state.playerCount, 2);
      expect(cubit.state.history, hasLength(2));
      expect(cubit.state.totalPlayed, 12);
      expect(cubit.state.streak.type, StreakType.win);
      expect(cubit.state.streak.count, 2);
      expect(cubit.state.headToHead, isEmpty);
      expect(cubit.state.recentMatches, hasLength(2));
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'the best rating is the higher of the current season and any past one',
    setUp: () {
      stubSeason();
      stubGameType(
        null,
        leaderboards: [_leaderboard('p1', 1000, 1)],
        seasonHistory: [_pastSeason(1120)],
      );
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.leaderboard?.rating, 1000);
      expect(cubit.state.bestRating, 1120);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'a season with no matches yet is ready with no leaderboard, history or streak',
    setUp: () => stubSeason(id: null),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.leaderboard, isNull);
      expect(cubit.state.history, isEmpty);
      expect(cubit.state.streak.type, StreakType.none);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'a player missing from the leaderboards (not yet played) has no leaderboard',
    setUp: () {
      stubSeason();
      stubGameType(null, leaderboards: [_leaderboard('p2', 960, 1)]);
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.leaderboard, isNull);
      expect(cubit.state.playerCount, 1);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'always loads total matches played and season history, even with no current-season matches',
    setUp: () {
      stubSeason(id: null);
      stubGameType(null, totalPlayed: 7, seasonHistory: [_pastSeason(1080)]);
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
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
      when(
        () =>
            profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
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
      stubGameType(null, leaderboards: [_leaderboard('p1', 1040, 1)]);
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
    setUp: () => when(
      () => leaderboardRepository.currentSeason('c1'),
    ).thenThrow(const NetworkFailure()),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProfileStatus.failed);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'selecting a game type refetches rank, rating, history, streak, totals, '
    'season history and recent matches for it',
    setUp: () {
      stubSeason();
      stubGameType(
        null,
        leaderboards: [_leaderboard('p1', 1040, 1)],
        totalPlayed: 12,
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
        seasonHistory: [_pastSeason(1150)],
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.selectGameTypeFilter(GameType.oneVOne);
      await _settle();
    },
    expect: () => [
      isA<ProfileState>().having(
        (s) => s.status,
        'status',
        ProfileStatus.loading,
      ),
      isA<ProfileState>()
          .having((s) => s.selectedGameType, 'selectedGameType', isNull)
          .having((s) => s.leaderboard?.rating, 'rating', 1040),
      isA<ProfileState>()
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
          .having(
            (s) => s.seasonHistory.single.seasonId,
            'seasonHistory',
            's-july',
          ),
    ],
    verify: (cubit) {
      expect(cubit.state.headToHead, isEmpty);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
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
    expect: () => [isA<ProfileState>(), isA<ProfileState>()],
  );

  blocTest<ProfileCubit, ProfileState>(
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
      expect(cubit.state.selectedGameType, GameType.oneVOne);
      expect(cubit.state.leaderboard?.rating, 1090);
    },
  );
}
