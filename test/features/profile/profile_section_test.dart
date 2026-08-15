import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.model.dart';
import 'package:keepscore2/features/profile/presentation/widgets/profile_section.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

Leaderboard _standing({
  int played = 5,
  int wins = 3,
  int losses = 1,
  int draws = 1,
  StreakType streakType = StreakType.none,
  int streakCount = 0,
}) => Leaderboard(
  seasonId: 's1',
  competitionId: 'c1',
  playerId: 'p1',
  displayName: 'Bartholomew Alexandertonovich',
  isClaimed: true,
  isOwner: false,
  rating: 1042,
  played: played,
  wins: wins,
  losses: losses,
  draws: draws,
  rank: 1,
  streakType: streakType,
  streakCount: streakCount,
);

Future<void> _pump(
  WidgetTester tester,
  Leaderboard? standing, {
  Medals? medals,
}) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, _) => ProfileSection(
        competitionId: 'c1',
        playerId: 'p1',
        displayName: 'Bartholomew Alexandertonovich',
        seasonLength: SeasonLength.monthly,
        playerCount: 6,
        standing: standing,
        medals: medals,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows the name without a greeting, and the rank, rating, win rate '
    'and games as text, with no streak or record',
    (tester) async {
      await _pump(tester, _standing());

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileSection)),
      );

      expect(find.text('Bartholomew Alexandertonovich'), findsOneWidget);
      expect(find.textContaining('Hello'), findsNothing);
      expect(find.text(l10n.profileRank(1, 6)), findsOneWidget);
      expect(find.text('1042'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text(l10n.profileSeasonGamesLabel), findsOneWidget);
      expect(find.text(l10n.leaderboardRecord(3, 1, 1)), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('omits the stats row when nothing has been played yet', (
    tester,
  ) async {
    await _pump(tester, _standing(played: 0, wins: 0, losses: 0, draws: 0));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ProfileSection)),
    );

    expect(find.text('Bartholomew Alexandertonovich'), findsOneWidget);
    expect(find.text(l10n.profileSeasonGamesLabel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('omits the stats row when there is no standing at all', (
    tester,
  ) async {
    await _pump(tester, null);

    expect(find.text('Bartholomew Alexandertonovich'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows medals in the header but never a streak', (tester) async {
    await _pump(
      tester,
      _standing(streakType: StreakType.win, streakCount: 7),
      medals: const Medals(playerId: 'p1', gold: 2, silver: 0, bronze: 1),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('7'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
