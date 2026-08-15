import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/profile/domain/profile_repository.dart';
import 'package:keepscore2/features/profile/domain/streak.model.dart';
import 'package:keepscore2/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:keepscore2/features/profile/presentation/widgets/profile_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

final _august = DateTime.utc(2026, 7, 31, 22);
final _september = DateTime.utc(2026, 8, 31, 22);

Leaderboard _standing({
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
  testWidgets(
    'the whole overview respects the selected game type, top to bottom',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final leaderboardRepository = MockLeaderboardRepository();
      final profileRepository = MockProfileRepository();
      final matchRepository = MockMatchRepository();

      void stubGameType(
        GameType? type, {
        required Leaderboard standing,
        required int totalPlayed,
        List<MatchEntry> recentMatches = const [],
      }) {
        when(
          () => leaderboardRepository.standings(
            competitionId: 'c1',
            seasonId: 's1',
            gameType: type,
          ),
        ).thenAnswer((_) async => [standing]);
        when(
          () => profileRepository.ratingHistory(
            seasonId: 's1',
            playerId: 'p1',
            gameType: type,
          ),
        ).thenAnswer((_) async => const []);
        when(
          () => profileRepository.currentStreak(
            seasonId: 's1',
            playerId: 'p1',
            gameType: type,
          ),
        ).thenAnswer((_) async => const Streak.none());
        when(
          () => profileRepository.totalMatchesPlayed(
            playerId: 'p1',
            gameType: type,
          ),
        ).thenAnswer((_) async => totalPlayed);
        when(
          () => matchRepository.recentForPlayer(playerId: 'p1', gameType: type),
        ).thenAnswer((_) async => recentMatches);
      }

      when(() => leaderboardRepository.currentSeason('c1')).thenAnswer(
        (_) async =>
            SeasonWindow(id: 's1', startsAt: _august, endsAt: _september),
      );
      when(
        () => leaderboardRepository.seasonHistory(
          competitionId: 'c1',
          playerId: 'p1',
        ),
      ).thenAnswer((_) async => const []);

      stubGameType(
        null,
        standing: _standing(
          rating: 1050,
          played: 5,
          wins: 3,
          losses: 1,
          draws: 1,
        ),
        totalPlayed: 20,
        recentMatches: [_matchAgainstTheo()],
      );
      stubGameType(
        GameType.oneVOne,
        standing: _standing(
          rating: 1090,
          played: 4,
          wins: 3,
          losses: 1,
          draws: 0,
        ),
        totalPlayed: 9,
      );
      when(
        () => leaderboardRepository.seasonHistory(
          competitionId: 'c1',
          playerId: 'p1',
          gameType: GameType.oneVOne,
        ),
      ).thenAnswer((_) async => const []);

      final gameTypeFilterCubit = GameTypeFilterCubit();
      addTearDown(gameTypeFilterCubit.close);

      final cubit = ProfileCubit(
        leaderboardRepository,
        profileRepository,
        matchRepository,
        gameTypeFilterCubit,
        'c1',
        'p1',
      );
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider<GameTypeFilterCubit>.value(
                value: gameTypeFilterCubit,
              ),
            ],
            child: const ProfileSheet(
              displayName: 'Nora',
              seasonLength: SeasonLength.monthly,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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

      SharedPreferences.setMockInitialValues({});
      final leaderboardRepository = MockLeaderboardRepository();
      final profileRepository = MockProfileRepository();
      final matchRepository = MockMatchRepository();

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
        () => leaderboardRepository.standings(
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
        () => profileRepository.currentStreak(
          seasonId: 's1',
          playerId: 'p1',
          gameType: null,
        ),
      ).thenAnswer((_) async => const Streak.none());
      when(
        () => profileRepository.totalMatchesPlayed(
          playerId: 'p1',
          gameType: null,
        ),
      ).thenAnswer((_) async => 42);
      when(
        () => matchRepository.recentForPlayer(playerId: 'p1', gameType: null),
      ).thenAnswer((_) async => const []);
      when(
        () => leaderboardRepository.seasonHistory(
          competitionId: 'c1',
          playerId: 'p1',
        ),
      ).thenAnswer((_) async => const []);

      final gameTypeFilterCubit = GameTypeFilterCubit();
      addTearDown(gameTypeFilterCubit.close);

      final cubit = ProfileCubit(
        leaderboardRepository,
        profileRepository,
        matchRepository,
        gameTypeFilterCubit,
        'c1',
        'p1',
      );
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider<GameTypeFilterCubit>.value(
                value: gameTypeFilterCubit,
              ),
            ],
            child: ProfileSheet(
              displayName: longName,
              seasonLength: SeasonLength.monthly,
              medals: const Medals(
                playerId: 'p1',
                gold: 12,
                silver: 34,
                bronze: 56,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
    SharedPreferences.setMockInitialValues({});
    final leaderboardRepository = MockLeaderboardRepository();
    final profileRepository = MockProfileRepository();
    final matchRepository = MockMatchRepository();

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
      () => leaderboardRepository.standings(
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
      () => profileRepository.currentStreak(
        seasonId: 's1',
        playerId: 'p1',
        gameType: null,
      ),
    ).thenAnswer((_) async => const Streak.none());
    when(
      () =>
          profileRepository.totalMatchesPlayed(playerId: 'p1', gameType: null),
    ).thenAnswer((_) async => 20);
    when(
      () => matchRepository.recentForPlayer(playerId: 'p1', gameType: null),
    ).thenAnswer((_) async => const []);
    when(
      () => leaderboardRepository.seasonHistory(
        competitionId: 'c1',
        playerId: 'p1',
      ),
    ).thenAnswer((_) async => const []);

    final gameTypeFilterCubit = GameTypeFilterCubit();
    addTearDown(gameTypeFilterCubit.close);

    final cubit = ProfileCubit(
      leaderboardRepository,
      profileRepository,
      matchRepository,
      gameTypeFilterCubit,
      'c1',
      'p1',
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
          ],
          child: const ProfileSheet(
            displayName: 'Nora',
            seasonLength: SeasonLength.monthly,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(ProfileSheet)));

    expect(find.text('1050'), findsNWidgets(2));
    expect(find.text('12.5'), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.leaderboardTodayGain('12.5')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await cubit.close();
  });
}
