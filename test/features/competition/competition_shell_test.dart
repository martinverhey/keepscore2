import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_section.enum.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_shell.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

void main() {
  tearDown(() {
    AppPlatform.debugOverrideWideWeb = null;
  });

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets(
    'wide web renders a sidebar with every section and the account actions',
    (tester) async {
      AppPlatform.debugOverrideWideWeb = true;
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var newMatchTapped = false;
      var homeTapped = false;
      var signedOut = false;
      CompetitionSection? selected;

      await tester.pumpWidget(
        wrap(
          CompetitionShell(
            competitionName: 'Office Table Tennis',
            current: CompetitionSection.leaderboard,
            canManageSettings: true,
            isRegistered: true,
            onSelectSection: (section) => selected = section,
            onNewMatch: () => newMatchTapped = true,
            onOpenHome: () => homeTapped = true,
            onOpenSettings: () {},
            onOpenTheme: () {},
            onSignOut: () => signedOut = true,
            child: const Center(child: Text('body content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.text('body content')));

      expect(find.text('Office Table Tennis'), findsOneWidget);
      expect(find.text(l10n.leaderboardTitle), findsOneWidget);
      expect(find.text(l10n.matchesTitle), findsOneWidget);
      expect(find.text(l10n.playersTitle), findsOneWidget);
      expect(find.text(l10n.historyTitle), findsOneWidget);
      expect(find.text(l10n.competitionSettingsTitle), findsOneWidget);
      expect(find.text(l10n.settingsThemeTitle), findsOneWidget);
      expect(find.text(l10n.authSignOut), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);

      await tester.tap(find.text(l10n.matchesTitle));
      expect(selected, CompetitionSection.matches);

      await tester.tap(find.text(l10n.matchNew));
      expect(newMatchTapped, isTrue);

      await tester.tap(find.text('KeepScore2'));
      expect(homeTapped, isTrue);

      await tester.tap(find.text(l10n.authSignOut));
      expect(signedOut, isTrue);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact/native renders only the child, no sidebar', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        CompetitionShell(
          competitionName: 'Office Table Tennis',
          current: CompetitionSection.leaderboard,
          canManageSettings: true,
          isRegistered: true,
          onSelectSection: (_) {},
          onNewMatch: () {},
          onOpenHome: () {},
          onOpenSettings: () {},
          onOpenTheme: () {},
          onSignOut: () {},
          child: const Center(child: Text('body content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('body content'), findsOneWidget);
    expect(find.text('KeepScore2'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
