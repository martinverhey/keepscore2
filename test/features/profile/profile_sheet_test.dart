import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/widgets/medal_chip.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/profile/domain/best_streaks.model.dart';
import 'package:keepscore2/features/profile/domain/head_to_head_record.model.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/profile_stats.model.dart';
import 'package:keepscore2/features/profile/domain/recent_played.model.dart';
import 'package:keepscore2/features/profile/domain/streak.model.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_history_cubit.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_overview_cubit.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_versus_cubit.dart';
import 'package:keepscore2/features/profile/presentation/widgets/profile_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

Leaderboard _leaderboard({
  required double rating,
  required int played,
  required int wins,
  required int losses,
  required int draws,
}) => Leaderboard(
  seasonId: 's1',
  competitionId: 'c1',
  playerId: 'p1',
  displayName: 'Nora',
  isClaimed: true,
  isOwner: false,
  rating: rating,
  played: played,
  wins: wins,
  losses: losses,
  draws: draws,
  rank: 1,
);

MatchEntry _matchAgainstTheo() => MatchEntry(
  id: 'm1',
  competitionId: 'c1',
  seasonId: 's1',
  playedAt: _august,
  teamAScore: 3,
  teamBScore: 1,
  teamARating: 1050,
  teamBRating: 950,
  teamA: const [
    MatchParticipant(
      playerId: 'p1',
      displayName: 'Nora',
      ratingBefore: 1020,
      ratingDelta: 30,
    ),
  ],
  teamB: const [
    MatchParticipant(
      playerId: 'p2',
      displayName: 'Theo',
      ratingBefore: 950,
      ratingDelta: -30,
    ),
  ],
);

void main() {
  late MockLeaderboardRepository leaderboardRepository;
  late MockProfileRepository profileRepository;
  late MockMatchRepository matchRepository;
  late GameTypeFilterCubit gameTypeFilterCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    leaderboardRepository = MockLeaderboardRepository();
    profileRepository = MockProfileRepository();
    matchRepository = MockMatchRepository();
    gameTypeFilterCubit = GameTypeFilterCubit();

    // The Versus and History tabs build their cubits lazily through
    // getIt, exactly the way the app does — registering them here means a
    // test only pays for the round trips of a tab it actually opens.
    getIt.registerFactoryParam<ProfileVersusCubit, String, String>(
      (playerId, opponentId) => ProfileVersusCubit(
        profileRepository,
        matchRepository,
        gameTypeFilterCubit,
        playerId,
        opponentId,
      ),
    );
    getIt.registerFactoryParam<ProfileHistoryCubit, String, String>(
      (competitionId, playerId) => ProfileHistoryCubit(
        leaderboardRepository,
        gameTypeFilterCubit,
        competitionId,
        playerId,
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await gameTypeFilterCubit.close();
  });

  ProfileOverviewCubit buildOverviewCubit() => ProfileOverviewCubit(
    leaderboardRepository,
    profileRepository,
    matchRepository,
    gameTypeFilterCubit,
    'c1',
    'p1',
  );

  Future<void> pumpSheet(
    WidgetTester tester,
    ProfileOverviewCubit cubit, {
    String displayName = 'Nora',
    String? myPlayerId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
          ],
          child: ProfileSheet(
            displayName: displayName,
            seasonLength: SeasonLength.monthly,
            myPlayerId: myPlayerId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the whole overview respects the selected game type, top to bottom, '
    'and never touches the versus or history repositories',
    (tester) async {
      void stubGameType(
        GameType? type, {
        required Leaderboard leaderboard,
        required int totalPlayed,
        List<MatchEntry> recentMatches = const [],
        List<Medals> medals = const [],
        double bestRating = 0,
      }) {
        when(
          () => leaderboardRepository.leaderboards(
            competitionId: 'c1',
            seasonId: 's1',
            gameType: type,
          ),
        ).thenAnswer((_) async => [leaderboard]);
        when(
          () => leaderboardRepository.medals('c1', gameType: type),
        ).thenAnswer((_) async => medals);
        when(
          () => profileRepository.ratingHistory(
            seasonId: 's1',
            playerId: 'p1',
            gameType: type,
          ),
        ).thenAnswer((_) async => const []);
        when(
          () => profileRepository.profileStats(
            playerId: 'p1',
            seasonId: any(named: 'seasonId'),
            gameType: type,
          ),
        ).thenAnswer(
          (_) async => ProfileStats(
            totalPlayed: totalPlayed,
            bestStreaks: const BestStreaks.zero(),
            bestRating: bestRating,
            streak: const Streak.none(),
            recentPlayed: const RecentPlayed.zero(),
          ),
        );
        when(
          () => matchRepository.recentForPlayer(playerId: 'p1', gameType: type),
        ).thenAnswer((_) async => recentMatches);
      }

      when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
        (_) async =>
            SeasonWindow(id: 's1', startsAt: _august, endsAt: _september),
      );

      stubGameType(
        null,
        leaderboard: _leaderboard(
          rating: 1050,
          played: 5,
          wins: 3,
          losses: 1,
          draws: 1,
        ),
        totalPlayed: 20,
        recentMatches: [_matchAgainstTheo()],
        medals: const [Medals(playerId: 'p1', gold: 1, silver: 0, bronze: 0)],
        bestRating: 1050,
      );
      stubGameType(
        GameType.oneVOne,
        leaderboard: _leaderboard(
          rating: 1090,
          played: 4,
          wins: 3,
          losses: 1,
          draws: 0,
        ),
        totalPlayed: 9,
        medals: const [Medals(playerId: 'p1', gold: 0, silver: 3, bronze: 0)],
        bestRating: 1090,
      );

      final cubit = buildOverviewCubit()..load();
      await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
      await pumpSheet(tester, cubit);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileSheet)),
      );

      expect(find.text(l10n.leaderboardFilterAll), findsOneWidget);
      expect(find.text(l10n.gameType1v1), findsNothing);

      // The win/loss/draw/win-rate grid appears exactly once — combined.
      expect(find.text(l10n.profileWinsLabel), findsOneWidget);
      expect(find.text(l10n.profileLossesLabel), findsOneWidget);
      expect(find.text(l10n.profileDrawsLabel), findsOneWidget);
      expect(find.text(l10n.profileWinRateLabel), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);

      expect(find.text(l10n.profileRank(1, 1)), findsOneWidget);
      expect(find.text(l10n.profileSeasonRatingLabel), findsOneWidget);
      expect(find.text(l10n.profileBestRatingLabel), findsOneWidget);
      expect(find.text('1050'), findsNWidgets(2));

      expect(find.text(l10n.profileSeasonGamesLabel), findsOneWidget);
      expect(find.text(l10n.profileTotalGamesLabel), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      expect(find.text(l10n.profileRecentMatchesTitle), findsOneWidget);
      expect(find.text('Theo'), findsOneWidget);

      expect(tester.widget<MedalChip>(find.byType(MedalChip)).count, 1);

      await tester.tap(find.text(l10n.leaderboardFilterAll));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.gameType1v1));
      await tester.pumpAndSettle();

      expect(find.text(l10n.gameType1v1), findsOneWidget);
      expect(find.text(l10n.leaderboardFilterAll), findsNothing);
      expect(find.text('1090'), findsNWidgets(2));
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text(l10n.profileRecentMatchesTitle), findsNothing);
      expect(tester.widget<MedalChip>(find.byType(MedalChip)).count, 3);

      // Neither Versus nor History was ever opened.
      verifyNever(
        () => profileRepository.headToHead(
          playerId: any(named: 'playerId'),
          opponentId: any(named: 'opponentId'),
        ),
      );
      verifyNever(
        () => leaderboardRepository.history(
          competitionId: any(named: 'competitionId'),
          playerId: any(named: 'playerId'),
        ),
      );

      expect(tester.takeException(), isNull);
      await cubit.close();
    },
  );

  testWidgets(
    'the rank + medals header subtitle does not overflow on a narrow phone '
    'with a long name and large counts',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const longName = 'Bartholomewski Alexandertononovich-Vandermeulen';
      final mine = Leaderboard(
        seasonId: 's1',
        competitionId: 'c1',
        playerId: 'p1',
        displayName: longName,
        isClaimed: true,
        isOwner: false,
        rating: 1234,
        played: 42,
        wins: 20,
        losses: 15,
        draws: 7,
        rank: 12,
      );
      final filler = List.generate(
        86,
        (i) => Leaderboard(
          seasonId: 's1',
          competitionId: 'c1',
          playerId: 'p$i',
          displayName: 'Player $i',
          isClaimed: true,
          isOwner: false,
          rating: 1000,
          played: 1,
          wins: 1,
          losses: 0,
          draws: 0,
          rank: i + 13,
        ),
      );

      when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
        (_) async =>
            SeasonWindow(id: 's1', startsAt: _august, endsAt: _september),
      );
      when(
        () => leaderboardRepository.leaderboards(
          competitionId: 'c1',
          seasonId: 's1',
          gameType: null,
        ),
      ).thenAnswer((_) async => [mine, ...filler]);
      when(
        () => profileRepository.ratingHistory(
          seasonId: 's1',
          playerId: 'p1',
          gameType: null,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => profileRepository.profileStats(
          playerId: 'p1',
          seasonId: any(named: 'seasonId'),
          gameType: null,
        ),
      ).thenAnswer(
        (_) async => const ProfileStats(
          totalPlayed: 42,
          bestStreaks: BestStreaks.zero(),
          bestRating: 1234,
          streak: Streak.none(),
          recentPlayed: RecentPlayed.zero(),
        ),
      );
      when(
        () => matchRepository.recentForPlayer(playerId: 'p1', gameType: null),
      ).thenAnswer((_) async => const []);
      when(() => leaderboardRepository.medals('c1', gameType: null)).thenAnswer(
        (_) async => const [
          Medals(playerId: 'p1', gold: 12, silver: 34, bronze: 56),
        ],
      );

      final cubit = buildOverviewCubit()..load();
      await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
      await pumpSheet(tester, cubit, displayName: longName);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileSheet)),
      );

      expect(find.text(l10n.profileRank(12, 87)), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('56'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await cubit.close();
    },
  );

  testWidgets("today's rating delta shows next to the season rating", (
    tester,
  ) async {
    final mine = Leaderboard(
      seasonId: 's1',
      competitionId: 'c1',
      playerId: 'p1',
      displayName: 'Nora',
      isClaimed: true,
      isOwner: false,
      rating: 1050,
      played: 5,
      wins: 3,
      losses: 1,
      draws: 1,
      rank: 1,
      todayDelta: 12.5,
    );

    when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
      (_) async =>
          SeasonWindow(id: 's1', startsAt: _august, endsAt: _september),
    );
    when(
      () => leaderboardRepository.leaderboards(
        competitionId: 'c1',
        seasonId: 's1',
        gameType: null,
      ),
    ).thenAnswer((_) async => [mine]);
    when(
      () => profileRepository.ratingHistory(
        seasonId: 's1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => profileRepository.profileStats(
        playerId: 'p1',
        seasonId: any(named: 'seasonId'),
        gameType: null,
      ),
    ).thenAnswer(
      (_) async => const ProfileStats(
        totalPlayed: 20,
        bestStreaks: BestStreaks.zero(),
        bestRating: 1050,
        streak: Streak.none(),
        recentPlayed: RecentPlayed.zero(),
      ),
    );
    when(
      () => matchRepository.recentForPlayer(playerId: 'p1', gameType: null),
    ).thenAnswer((_) async => const []);
    when(
      () => leaderboardRepository.medals('c1', gameType: null),
    ).thenAnswer((_) async => const []);

    final cubit = buildOverviewCubit()..load();
    await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
    await pumpSheet(tester, cubit);

    final l10n = AppLocalizations.of(tester.element(find.byType(ProfileSheet)));

    expect(find.text('1050'), findsNWidgets(2));
    expect(find.text('12.5'), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.leaderboardTodayGain('12.5')),
      findsOneWidget,
    );
    expect(find.text(l10n.profileTabVersus), findsNothing);
    expect(tester.takeException(), isNull);

    await cubit.close();
  });

  testWidgets(
    'a versus tab appears only when there is someone to compare against, '
    'and lazily loads its own record — only once opened',
    (tester) async {
      when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
        (_) async =>
            SeasonWindow(id: 's1', startsAt: _august, endsAt: _september),
      );
      when(
        () => leaderboardRepository.leaderboards(
          competitionId: 'c1',
          seasonId: 's1',
          gameType: null,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => profileRepository.ratingHistory(
          seasonId: 's1',
          playerId: 'p1',
          gameType: null,
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => profileRepository.profileStats(
          playerId: 'p1',
          seasonId: any(named: 'seasonId'),
          gameType: null,
        ),
      ).thenAnswer(
        (_) async => const ProfileStats(
          totalPlayed: 0,
          bestStreaks: BestStreaks.zero(),
          bestRating: 0,
          streak: Streak.none(),
          recentPlayed: RecentPlayed.zero(),
        ),
      );
      when(
        () => matchRepository.recentForPlayer(playerId: 'p1', gameType: null),
      ).thenAnswer((_) async => const []);
      when(
        () => leaderboardRepository.medals('c1', gameType: null),
      ).thenAnswer((_) async => const []);
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
          HeadToHeadRecord(
            gameType: GameType.twoVTwo,
            wins: 1,
            losses: 0,
            draws: 1,
          ),
        ],
      );
      when(
        () => matchRepository.recentBetweenPlayers(
          playerId: 'p1',
          opponentId: 'viewer',
          gameType: null,
        ),
      ).thenAnswer((_) async => [_matchAgainstTheo()]);

      final cubit = buildOverviewCubit()..load(viewerPlayerId: 'viewer');
      await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
      await pumpSheet(tester, cubit, myPlayerId: 'viewer');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileSheet)),
      );

      expect(find.text(l10n.profileTabVersus), findsOneWidget);
      // Nothing versus-shaped has been fetched before the tab is opened.
      verifyNever(
        () => profileRepository.headToHead(
          playerId: any(named: 'playerId'),
          opponentId: any(named: 'opponentId'),
        ),
      );

      await tester.tap(find.text(l10n.profileTabVersus));
      await tester.pumpAndSettle();

      // Just the aggregated record table: 4 wins, 1 loss, 1 draw, 67% —
      // no per-game-type breakdown and no "Your record vs" header.
      expect(find.text(l10n.profileWinsLabel), findsOneWidget);
      expect(find.text(l10n.profileLossesLabel), findsOneWidget);
      expect(find.text(l10n.profileDrawsLabel), findsOneWidget);
      expect(find.text(l10n.profileWinRateLabel), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('67%'), findsOneWidget);
      expect(find.text(l10n.profileHeadToHeadTitle('Nora')), findsNothing);
      expect(find.text(l10n.gameType1v1), findsNothing);
      expect(find.text(l10n.gameType2v2), findsNothing);

      // The versus-specific recent matches, same list style as overview.
      expect(find.text(l10n.profileRecentMatchesTitle), findsOneWidget);
      expect(find.text('Theo'), findsOneWidget);
      expect(tester.takeException(), isNull);

      verify(
        () =>
            profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
      ).called(1);

      await cubit.close();
    },
  );

  testWidgets('the history tab lazily loads leaderboards only once opened', (
    tester,
  ) async {
    when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
      (_) async =>
          SeasonWindow(id: 's1', startsAt: _august, endsAt: _september),
    );
    when(
      () => leaderboardRepository.leaderboards(
        competitionId: 'c1',
        seasonId: 's1',
        gameType: null,
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => profileRepository.ratingHistory(
        seasonId: 's1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => profileRepository.profileStats(
        playerId: 'p1',
        seasonId: any(named: 'seasonId'),
        gameType: null,
      ),
    ).thenAnswer(
      (_) async => const ProfileStats(
        totalPlayed: 0,
        bestStreaks: BestStreaks.zero(),
        bestRating: 0,
        streak: Streak.none(),
        recentPlayed: RecentPlayed.zero(),
      ),
    );
    when(
      () => matchRepository.recentForPlayer(playerId: 'p1', gameType: null),
    ).thenAnswer((_) async => const []);
    when(
      () => leaderboardRepository.medals('c1', gameType: null),
    ).thenAnswer((_) async => const []);
    when(
      () => leaderboardRepository.history(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenAnswer((_) async => const []);

    final cubit = buildOverviewCubit()..load();
    await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
    await pumpSheet(tester, cubit);

    final l10n = AppLocalizations.of(tester.element(find.byType(ProfileSheet)));

    verifyNever(
      () => leaderboardRepository.history(
        competitionId: any(named: 'competitionId'),
        playerId: any(named: 'playerId'),
      ),
    );

    await tester.tap(find.text(l10n.profileTabHistory));
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileHistoryEmpty), findsOneWidget);
    verify(
      () => leaderboardRepository.history(
        competitionId: 'c1',
        playerId: 'p1',
        gameType: null,
      ),
    ).called(1);
    expect(tester.takeException(), isNull);

    await cubit.close();
  });
}
