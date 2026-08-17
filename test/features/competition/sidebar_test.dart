import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_section.enum.dart';
import 'package:keepscore2/features/competition/presentation/widgets/sidebar.dart';
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
          Sidebar(
            competitionName: 'Office Table Tennis',
            current: CompetitionSection.leaderboard,
            canManageSettings: true,
            isRegistered: true,
            onSelectSection: (section) => selected = section,
            onNewMatch: () => newMatchTapped = true,
            onOpenHome: () => homeTapped = true,
            onOpenTheme: () {},
            onSignOut: () => signedOut = true,
            child: const Center(child: Text('body content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.text('body content')),
      );

      expect(find.text('Office Table Tennis'), findsOneWidget);
      expect(find.text(l10n.leaderboardTitle), findsOneWidget);
      expect(find.text(l10n.matchesTitle), findsOneWidget);
      expect(
        find.text(l10n.competitionSettingsSectionCompetition),
        findsOneWidget,
      );
      expect(find.text(l10n.configurationTitle), findsOneWidget);
      expect(find.text(l10n.historyTitle), findsOneWidget);
      expect(find.text(l10n.playersManageTitle), findsOneWidget);
      expect(find.text(l10n.competitionSettingsSectionUser), findsOneWidget);
      expect(find.text(l10n.competitionsTitle), findsOneWidget);
      expect(find.text(l10n.settingsThemeTitle), findsOneWidget);
      expect(find.text(l10n.authSignOut), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);

      await tester.tap(find.text(l10n.matchesTitle));
      expect(selected, CompetitionSection.matches);

      await tester.tap(find.text(l10n.playersManageTitle));
      expect(selected, CompetitionSection.players);

      await tester.tap(find.text(l10n.configurationTitle));
      expect(selected, CompetitionSection.configuration);

      await tester.tap(find.text(l10n.matchNew));
      expect(newMatchTapped, isTrue);

      await tester.tap(find.text(l10n.competitionsTitle));
      expect(homeTapped, isTrue);

      await tester.tap(find.text(l10n.authSignOut));
      expect(signedOut, isTrue);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wide web hides competition-scoped items when there is no competition '
    'to fall back to',
    (tester) async {
      AppPlatform.debugOverrideWideWeb = true;
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          Sidebar(
            competitionName: null,
            current: CompetitionSection.competitions,
            hasCompetition: false,
            canManageSettings: false,
            isRegistered: true,
            onSelectSection: (_) {},
            onNewMatch: () {},
            onOpenHome: () {},
            onOpenTheme: () {},
            onSignOut: () {},
            child: const Center(child: Text('body content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.text('body content')),
      );

      expect(find.text(l10n.matchNew), findsNothing);
      expect(find.text(l10n.leaderboardTitle), findsNothing);
      expect(
        find.text(l10n.competitionSettingsSectionCompetition),
        findsNothing,
      );
      expect(find.text(l10n.competitionsTitle), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wide web keeps the competition-scoped items when Competitions was '
    'reached from within one, so the user can jump straight back',
    (tester) async {
      AppPlatform.debugOverrideWideWeb = true;
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CompetitionSection? selected;

      await tester.pumpWidget(
        wrap(
          Sidebar(
            competitionName: 'Office Table Tennis',
            current: CompetitionSection.competitions,
            canManageSettings: true,
            isRegistered: true,
            onSelectSection: (section) => selected = section,
            onNewMatch: () {},
            onOpenHome: () {},
            onOpenTheme: () {},
            onSignOut: () {},
            child: const Center(child: Text('body content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.text('body content')),
      );

      expect(find.text('Office Table Tennis'), findsOneWidget);
      expect(find.text(l10n.leaderboardTitle), findsOneWidget);
      expect(find.text(l10n.playersManageTitle), findsOneWidget);

      await tester.tap(find.text(l10n.leaderboardTitle));
      expect(selected, CompetitionSection.leaderboard);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact/native renders only the child, no sidebar', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Sidebar(
          competitionName: 'Office Table Tennis',
          current: CompetitionSection.leaderboard,
          canManageSettings: true,
          isRegistered: true,
          onSelectSection: (_) {},
          onNewMatch: () {},
          onOpenHome: () {},
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

  testWidgets('wide web sidebar suppresses the pushed page back button', (
    tester,
  ) async {
    AppPlatform.debugOverrideWideWeb = true;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Center(child: Text('root')),
          routes: [
            GoRoute(
              path: 'pushed',
              builder: (context, state) => Sidebar(
                competitionName: 'Office Table Tennis',
                current: CompetitionSection.history,
                canManageSettings: true,
                isRegistered: true,
                onSelectSection: (_) {},
                onNewMatch: () {},
                onOpenHome: () {},
                onOpenTheme: () {},
                onSignOut: () {},
                child: const AdaptiveScaffold(
                  title: 'History',
                  body: Text('history body'),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    router.push('/pushed');
    await tester.pumpAndSettle();

    expect(find.text('history body'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(CloseButton), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
