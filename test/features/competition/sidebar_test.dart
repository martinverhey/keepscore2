import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/presentation/widgets/home_sidebar_competition.dart';
import 'package:keepscore2/features/competition/presentation/widgets/sidebar.dart';
import 'package:keepscore2/features/competition/presentation/widgets/sidebar_section.enum.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _competition = HomeSidebarCompetition(
  competitionId: 'c1',
  competitionName: 'Office Table Tennis',
  canManageSettings: true,
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository auth;
  late AuthBloc authBloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    auth = MockAuthRepository();
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
    when(() => auth.signOut()).thenAnswer((_) async {});
    authBloc = AuthBloc(auth);
    addTearDown(authBloc.close);
  });

  tearDown(() {
    AppPlatform.debugOverrideWideWeb = null;
    binding.platformDispatcher.clearPlatformBrightnessTestValue();
  });

  void useWideWebViewport(WidgetTester tester) {
    AppPlatform.debugOverrideWideWeb = true;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget withProviders(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<AuthBloc>.value(value: authBloc),
    ],
    child: child,
  );

  Widget wrap(Widget child) => withProviders(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  testWidgets(
    'wide web renders a sidebar with every section and the account actions',
    (tester) async {
      useWideWebViewport(tester);

      SidebarSection? selected;

      await tester.pumpWidget(
        wrap(
          Sidebar(
            competition: _competition,
            current: SidebarSection.leaderboard,
            onSelectSection: (section) => selected = section,
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
      expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);
      expect(find.text(l10n.authSignOut), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);

      await tester.tap(find.text(l10n.matchesTitle));
      expect(selected, SidebarSection.matches);

      await tester.tap(find.text(l10n.playersManageTitle));
      expect(selected, SidebarSection.players);

      await tester.tap(find.text(l10n.configurationTitle));
      expect(selected, SidebarSection.configuration);

      await tester.tap(find.text(l10n.matchNew));
      expect(selected, SidebarSection.newMatch);

      await tester.tap(find.text(l10n.competitionsTitle));
      expect(selected, SidebarSection.competitions);

      await tester.tap(find.text(l10n.settingsLanguageTitle));
      expect(selected, SidebarSection.language);

      await tester.tap(find.text(l10n.authSignOut));
      await tester.pumpAndSettle();
      verify(() => auth.signOut()).called(1);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact/native renders only the child, no sidebar', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Sidebar(
          competition: _competition,
          current: SidebarSection.leaderboard,
          onSelectSection: (_) {},
          child: const Center(child: Text('body content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('body content'), findsOneWidget);
    expect(find.text('KeepScore2'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the section already shown does nothing', (tester) async {
    useWideWebViewport(tester);

    var selections = 0;

    await tester.pumpWidget(
      wrap(
        Sidebar(
          competition: _competition,
          current: SidebarSection.leaderboard,
          onSelectSection: (_) => selections++,
          child: const Center(child: Text('body content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.text('body content')));

    await tester.tap(find.text(l10n.leaderboardTitle));
    expect(selections, 0);

    await tester.tap(find.text(l10n.matchesTitle));
    expect(selections, 1);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide web hides competition-scoped items when there is no competition '
    'to fall back to',
    (tester) async {
      useWideWebViewport(tester);

      await tester.pumpWidget(
        wrap(
          Sidebar(
            competition: null,
            current: SidebarSection.competitions,
            onSelectSection: (_) {},
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
      expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wide web keeps the competition-scoped items when Competitions was '
    'reached from within one, so the user can jump straight back',
    (tester) async {
      useWideWebViewport(tester);

      SidebarSection? selected;

      await tester.pumpWidget(
        wrap(
          Sidebar(
            competition: _competition,
            current: SidebarSection.competitions,
            onSelectSection: (section) => selected = section,
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
      expect(selected, SidebarSection.leaderboard);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a pushed page pops its picked section back to the page underneath, '
    'however deep the user went',
    (tester) async {
      useWideWebViewport(tester);

      SidebarSection? received;

      Widget sidebarPage(SidebarSection current, String body) => Sidebar(
        competition: _competition,
        current: current,
        child: AdaptiveScaffold(title: body, body: Text(body)),
      );

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Center(
              child: TextButton(
                onPressed: () async =>
                    received = await context.push<SidebarSection>('/history'),
                child: const Text('open history'),
              ),
            ),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) =>
                    sidebarPage(SidebarSection.history, 'history body'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        withProviders(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open history'));
      await tester.pumpAndSettle();
      expect(find.text('history body'), findsWidgets);

      final l10n = AppLocalizations.of(
        tester.element(find.text('history body').first),
      );

      await tester.tap(find.text(l10n.leaderboardTitle));
      await tester.pumpAndSettle();

      expect(received, SidebarSection.leaderboard);
      expect(find.text('open history'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wide web sidebar suppresses the pushed page back button', (
    tester,
  ) async {
    useWideWebViewport(tester);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Center(child: Text('root')),
          routes: [
            GoRoute(
              path: 'pushed',
              builder: (context, state) => Sidebar(
                competition: _competition,
                current: SidebarSection.history,
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
      withProviders(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.push('/pushed');
    await tester.pumpAndSettle();

    expect(find.text('history body'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sidebar theme row toggles between light and dark', (
    tester,
  ) async {
    useWideWebViewport(tester);

    final themeCubit = ThemeCubit();
    addTearDown(themeCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Sidebar(
            competition: _competition,
            current: SidebarSection.leaderboard,
            onSelectSection: (_) {},
            child: const Center(child: Text('body content')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.text('body content')));

    final before = themeCubit.state.preference;
    await tester.tap(find.text(l10n.settingsThemeTitle));
    await tester.pumpAndSettle();

    expect(themeCubit.state.preference, isNot(before));
    expect(tester.takeException(), isNull);
  });
}
