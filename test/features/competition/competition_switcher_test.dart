import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/router/app_router.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/auth/presentation/widgets/guest_notice.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competition_switcher_sheet.dart';
import 'package:keepscore2/features/competition/presentation/pages/welcome.page.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_caption.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

CompetitionOverview _overview(String id, String name) => CompetitionOverview(
  competition: Competition(
    id: id,
    joinCode: 'HDHS39',
    name: name,
    ownerId: 'someone-else',
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    allowDraws: true,
    createdAt: DateTime.utc(2026, 8, 1),
  ),
  playerCount: 5,
  matchCount: 11,
  myPlayerId: 'player-$id',
);

void main() {
  late MockCompetitionRepository competitions;
  late AuthBloc authBloc;
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
        _overview('c2', 'Padel Ladder'),
      ],
    );
    when(
      () => competitions.overview('c1'),
    ).thenAnswer((_) async => _overview('c1', 'Office Table Tennis'));

    authBloc = AuthBloc(auth);
    competitionCubit = CompetitionCubit(competitions, authBloc);
    competitionListCubit = CompetitionListCubit(competitions, authBloc);
  });

  tearDown(() async {
    AppPlatform.debugOverrideCupertino = null;
    await competitionListCubit.close();
    await competitionCubit.close();
    await authBloc.close();
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
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<CompetitionCubit>.value(value: competitionCubit),
          BlocProvider<CompetitionListCubit>.value(value: competitionListCubit),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    expect(find.text('Current'), findsOneWidget);

    await tester.tap(find.text('Padel Ladder'));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionSwitcherSheet), findsNothing);
    expect(locationOf(router), Routes.leaderboard('c2'));
    expect(tester.takeException(), isNull);
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
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<CompetitionCubit>.value(value: competitionCubit),
            BlocProvider<CompetitionListCubit>.value(
              value: competitionListCubit,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
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
