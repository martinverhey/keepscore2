import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/app.dart';
import 'package:keepscore2/app/router/app_router.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:keepscore2/features/auth/presentation/widgets/guest_notice.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/create_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competition_switcher_sheet.dart';
import 'package:keepscore2/features/competition/presentation/pages/create_competition_sheet.dart';
import 'package:keepscore2/features/competition/presentation/pages/join_scanner_sheet.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_switcher_row.dart';
import 'package:keepscore2/features/competition/presentation/pages/welcome.page.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_caption.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

CompetitionOverview _overview(
  String id,
  String name, {
  String ownerId = 'someone-else',
}) => CompetitionOverview(
  competition: Competition(
    id: id,
    joinCode: 'HDHS39',
    name: name,
    ownerId: ownerId,
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    createdAt: DateTime.utc(2026, 8, 1),
  ),
  playerCount: 5,
  matchCount: 11,
  myPlayerId: 'player-$id',
);

void main() {
  late MockCompetitionRepository competitions;
  late AuthCubit authCubit;
  late CompetitionCubit competitionCubit;
  late CompetitionListCubit competitionListCubit;

  setUp(() {
    AppPlatform.debugOverrideCupertino = false;
    SharedPreferences.setMockInitialValues({});

    final auth = MockAuthRepository();
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

    competitions = MockCompetitionRepository();
    when(() => competitions.myCompetitions()).thenAnswer(
      (_) async => [
        _overview('c1', 'Office Table Tennis'),
        _overview('c2', 'Padel Ladder', ownerId: 'user-1'),
      ],
    );
    when(
      () => competitions.overview('c1'),
    ).thenAnswer((_) async => _overview('c1', 'Office Table Tennis'));

    authCubit = AuthCubit(auth);
    competitionCubit = CompetitionCubit(competitions, authCubit);
    competitionListCubit = CompetitionListCubit(competitions, authCubit);
  });

  tearDown(() async {
    AppPlatform.debugOverrideCupertino = null;
    await competitionListCubit.close();
    await competitionCubit.close();
    await authCubit.close();
  });

  Future<GoRouter> pumpPill(WidgetTester tester) async {
    await competitionCubit.select('c1');
    final router = GoRouter(
      initialLocation: Routes.leaderboard('c1'),
      routes: [
        GoRoute(
          path: '/competition/:id',
          redirect: (context, state) => state.matchedLocation == state.uri.path
              ? '${state.matchedLocation}/leaderboard'
              : null,
          routes: [
            GoRoute(
              path: 'leaderboard',
              builder: (context, state) => Scaffold(
                body: Column(
                  children: [
                    Builder(
                      builder: (context) => GestureDetector(
                        onTap: () => openCompetitionSwitcher(context),
                        child: const CompetitionCaption(),
                      ),
                    ),
                    Text('board ${state.pathParameters['id']}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<CompetitionCubit>.value(value: competitionCubit),
          BlocProvider<CompetitionListCubit>.value(value: competitionListCubit),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: KeepScoreApp.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('the sheet switches to the competition picked in it', (
    tester,
  ) async {
    final router = await pumpPill(tester);

    await tester.tap(find.byType(CompetitionCaption));
    await tester.pumpAndSettle();
    expect(find.byType(CompetitionSwitcherSheet), findsOneWidget);
    expect(find.text('Not played yet'), findsNWidgets(2));

    await tester.tap(find.text('Padel Ladder'));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionSwitcherSheet), findsNothing);
    expect(locationOf(router), Routes.leaderboard('c2'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tags the competitions the viewer owns', (tester) async {
    await pumpPill(tester);

    await tester.tap(find.byType(CompetitionCaption));
    await tester.pumpAndSettle();

    final ownedRow = find.ancestor(
      of: find.text('Padel Ladder'),
      matching: find.byType(CompetitionSwitcherRow),
    );
    expect(
      find.descendant(of: ownedRow, matching: find.text('Owner')),
      findsOneWidget,
    );
    expect(find.text('Owner'), findsOneWidget);
  });

  testWidgets('tapping the current competition only closes the sheet', (
    tester,
  ) async {
    final router = await pumpPill(tester);
    final before = locationOf(router);

    await tester.tap(find.byType(CompetitionCaption));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CompetitionSwitcherSheet),
        matching: find.text('Office Table Tennis'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionSwitcherSheet), findsNothing);
    expect(locationOf(router), before);
    expect(tester.takeException(), isNull);
  });

  Finder headerAction(AdaptiveGlyph glyph) => find.descendant(
    of: find.byType(CompetitionSwitcherSheet),
    matching: find.byWidgetPredicate(
      (widget) => widget is AdaptiveBarAction && widget.glyph == glyph,
    ),
  );

  Future<void> openSwitcher(WidgetTester tester) async {
    await pumpPill(tester);
    await tester.tap(find.byType(CompetitionCaption));
    await tester.pumpAndSettle();
  }

  testWidgets('the header carries join and create, centred on the title', (
    tester,
  ) async {
    await openSwitcher(tester);

    final sheet = find.byType(CompetitionSwitcherSheet);
    final l10n = AppLocalizations.of(tester.element(sheet));
    final title = find.descendant(
      of: sheet,
      matching: find.text(l10n.competitionsTitle),
    );
    final titleCentre = tester.getCenter(title).dy;

    for (final glyph in [AdaptiveGlyph.scan, AdaptiveGlyph.add]) {
      expect(headerAction(glyph), findsOneWidget);
      expect(
        tester.getCenter(headerAction(glyph)).dy,
        moreOrLessEquals(titleCentre, epsilon: 0.5),
      );
    }
    expect(find.text(l10n.competitionsCreateShort), findsNothing);
  });

  testWidgets('the header join action swaps the sheet for the scanner', (
    tester,
  ) async {
    await openSwitcher(tester);

    await tester.tap(headerAction(AdaptiveGlyph.scan));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionSwitcherSheet), findsNothing);
    expect(find.byType(JoinScannerSheet), findsOneWidget);
  });

  testWidgets('dismissing the scanner reopens the sheet', (tester) async {
    await openSwitcher(tester);

    await tester.tap(headerAction(AdaptiveGlyph.scan));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(JoinScannerSheet), findsNothing);
    expect(find.byType(CompetitionSwitcherSheet), findsOneWidget);
  });

  testWidgets('the header create action swaps the sheet for the create one', (
    tester,
  ) async {
    getIt.registerFactory<CreateCompetitionCubit>(
      () => CreateCompetitionCubit(competitions),
    );
    addTearDown(() => getIt.reset(dispose: false));
    await openSwitcher(tester);

    await tester.tap(headerAction(AdaptiveGlyph.add));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionSwitcherSheet), findsNothing);
    expect(find.byType(CreateCompetitionSheet), findsOneWidget);
  });

  group('WelcomePage', () {
    Future<GoRouter> pumpWelcome(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: Routes.home,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const WelcomePage()),
          GoRoute(
            path: '/competition/:id',
            builder: (_, state) =>
                Text('entered ${state.pathParameters['id']}'),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<CompetitionCubit>.value(value: competitionCubit),
            BlocProvider<CompetitionListCubit>.value(
              value: competitionListCubit,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: KeepScoreApp.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('offers join and create when there is nothing to enter', (
      tester,
    ) async {
      when(() => competitions.myCompetitions()).thenAnswer((_) async => []);

      await pumpWelcome(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(WelcomePage)),
      );

      expect(find.text(l10n.competitionsJoin), findsOneWidget);
      expect(find.text(l10n.competitionsCreate), findsOneWidget);
      expect(find.byType(GuestNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('enters the newest competition once the list has one', (
      tester,
    ) async {
      final router = await pumpWelcome(tester);

      expect(locationOf(router), Routes.competition('c1'));
      expect(find.text('entered c1'), findsOneWidget);
    });
  });
}
