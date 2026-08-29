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
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
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
  teamBScore: 2,
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

  setUp(() {
    leaderboardRepository = MockLeaderboardRepository();
    profileRepository = MockProfileRepository();
    matchRepository = MockMatchRepository();

    getIt.registerFactoryParam<ProfileVersusCubit, String, String>(
      (playerId, opponentId) => ProfileVersusCubit(
        profileRepository,
        matchRepository,
        playerId,
        opponentId,
      ),
    );
    getIt.registerFactoryParam<ProfileHistoryCubit, String, String>(
      (competitionId, playerId) =>
          ProfileHistoryCubit(leaderboardRepository, competitionId, playerId),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  ProfileOverviewCubit buildOverviewCubit() => ProfileOverviewCubit(
    leaderboardRepository,
    profileRepository,
    matchRepository,
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
        home: BlocProvider.value(
          value: cubit,
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
    'the overview renders rank, record, games and recent matches, and '
    'never touches the versus or history repositories',
    (tester) async {
      when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
        (_) async =>
            SeasonWindow(id: 's1', startsAt: _august, endsAt: _september),
      );
      when(
        () => leaderboardRepository.leaderboards(
          competitionId: 'c1',
          seasonId: 's1',
        ),
      ).thenAnswer(
        (_) async => [
          _leaderboard(rating: 1050, played: 5, wins: 3, losses: 1, draws: 1),
        ],
      );
      when(() => leaderboardRepository.medals('c1')).thenAnswer(
        (_) async => const [
          Medals(playerId: 'p1', gold: 1, silver: 0, bronze: 0),
        ],
      );
      when(
        () => profileRepository.ratingHistory(seasonId: 's1', playerId: 'p1'),
      ).thenAnswer((_) async => const []);
      when(
        () => profileRepository.profileStats(
          playerId: 'p1',
          seasonId: any(named: 'seasonId'),
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
        () => matchRepository.recentForPlayer(playerId: 'p1'),
      ).thenAnswer((_) async => [_matchAgainstTheo()]);

      final cubit = buildOverviewCubit()..load();
      await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
      await pumpSheet(tester, cubit);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileSheet)),
      );

      expect(find.text(l10n.profileWinsLabel), findsOneWidget);
      expect(find.text(l10n.profileLossesLabel), findsOneWidget);
      expect(find.text(l10n.profileDrawsLabel), findsOneWidget);
      expect(find.text(l10n.profileWinRateLabel), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);

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
    'the medals header subtitle does not overflow on a narrow phone '
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
        ),
      ).thenAnswer((_) async => [mine, ...filler]);
      when(
        () => profileRepository.ratingHistory(seasonId: 's1', playerId: 'p1'),
      ).thenAnswer((_) async => const []);
      when(
        () => profileRepository.profileStats(
          playerId: 'p1',
          seasonId: any(named: 'seasonId'),
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
        () => matchRepository.recentForPlayer(playerId: 'p1'),
      ).thenAnswer((_) async => const []);
      when(() => leaderboardRepository.medals('c1')).thenAnswer(
        (_) async => const [
          Medals(playerId: 'p1', gold: 12, silver: 34, bronze: 56),
        ],
      );

      final cubit = buildOverviewCubit()..load();
      await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
      await pumpSheet(tester, cubit, displayName: longName);

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
      ),
    ).thenAnswer((_) async => [mine]);
    when(
      () => profileRepository.ratingHistory(seasonId: 's1', playerId: 'p1'),
    ).thenAnswer((_) async => const []);
    when(
      () => profileRepository.profileStats(
        playerId: 'p1',
        seasonId: any(named: 'seasonId'),
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
      () => matchRepository.recentForPlayer(playerId: 'p1'),
    ).thenAnswer((_) async => const []);
    when(
      () => leaderboardRepository.medals('c1'),
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
        ),
      ).thenAnswer((_) async => const []);
      when(
        () => profileRepository.ratingHistory(seasonId: 's1', playerId: 'p1'),
      ).thenAnswer((_) async => const []);
      when(
        () => profileRepository.profileStats(
          playerId: 'p1',
          seasonId: any(named: 'seasonId'),
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
        () => matchRepository.recentForPlayer(playerId: 'p1'),
      ).thenAnswer((_) async => const []);
      when(
        () => leaderboardRepository.medals('c1'),
      ).thenAnswer((_) async => const []);
      when(
        () =>
            profileRepository.headToHead(playerId: 'p1', opponentId: 'viewer'),
      ).thenAnswer(
        (_) async => const HeadToHeadRecord(wins: 4, losses: 1, draws: 1),
      );
      when(
        () => matchRepository.recentBetweenPlayers(
          playerId: 'p1',
          opponentId: 'viewer',
        ),
      ).thenAnswer((_) async => [_matchAgainstTheo()]);

      final cubit = buildOverviewCubit()..load(viewerPlayerId: 'viewer');
      await cubit.stream.firstWhere((s) => s is ProfileOverviewReady);
      await pumpSheet(tester, cubit, myPlayerId: 'viewer');

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileSheet)),
      );

      expect(find.text(l10n.profileTabVersus), findsOneWidget);
      verifyNever(
        () => profileRepository.headToHead(
          playerId: any(named: 'playerId'),
          opponentId: any(named: 'opponentId'),
        ),
      );

      await tester.tap(find.text(l10n.profileTabVersus));
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileWinsLabel), findsOneWidget);
      expect(find.text(l10n.profileLossesLabel), findsOneWidget);
      expect(find.text(l10n.profileDrawsLabel), findsOneWidget);
      expect(find.text(l10n.profileWinRateLabel), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('67%'), findsOneWidget);
      expect(find.text(l10n.profileHeadToHeadTitle('Nora')), findsNothing);

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
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => profileRepository.ratingHistory(seasonId: 's1', playerId: 'p1'),
    ).thenAnswer((_) async => const []);
    when(
      () => profileRepository.profileStats(
        playerId: 'p1',
        seasonId: any(named: 'seasonId'),
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
      () => matchRepository.recentForPlayer(playerId: 'p1'),
    ).thenAnswer((_) async => const []);
    when(
      () => leaderboardRepository.medals('c1'),
    ).thenAnswer((_) async => const []);
    when(
      () => leaderboardRepository.history(competitionId: 'c1', playerId: 'p1'),
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
      () => leaderboardRepository.history(competitionId: 'c1', playerId: 'p1'),
    ).called(1);
    expect(tester.takeException(), isNull);

    await cubit.close();
  });
}
