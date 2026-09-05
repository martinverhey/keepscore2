import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive_floating_action.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competition_shell.dart';
import 'package:keepscore2/features/competition/presentation/pages/competitions.page.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_scope.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_tab.enum.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_tab_bar.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/leaderboard/presentation/pages/leaderboard.page.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:keepscore2/features/match/presentation/pages/matches.page.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

const _competitionId = 'c1';

Future<GoRouter> _pumpHarness(
  WidgetTester tester, {
  String initialLocation = '/competition/$_competitionId/leaderboard',
  StreamController<AuthUser?>? userChanges,
}) async {
  SharedPreferences.setMockInitialValues({});

  final auth = MockAuthRepository();
  final competitions = MockCompetitionRepository();
  final players = MockPlayerRepository();
  final matches = MockMatchRepository();
  final leaderboard = MockLeaderboardRepository();

  when(
    () => auth.currentUser,
  ).thenReturn(const AuthUser(id: 'p-ada', displayName: 'Ada', isGuest: false));
  when(
    () => auth.watchUser(),
  ).thenAnswer((_) => userChanges?.stream ?? const Stream.empty());

  when(() => competitions.overview(_competitionId)).thenAnswer(
    (_) async => CompetitionOverview(
      competition: Competition(
        id: _competitionId,
        joinCode: 'HDHS39',
        name: 'Office Table Tennis',
        ownerId: 'p-ada',
        seasonLength: SeasonLength.monthly,
        timezone: 'Europe/Amsterdam',
        startingRating: 1000,
        kFactor: 32,
        movEnabled: true,
        movCap: 2.5,
        allowDraws: true,
        createdAt: DateTime.utc(2026, 8, 1),
      ),
      playerCount: 1,
      matchCount: 0,
      myPlayerId: 'p-ada',
    ),
  );
  when(() => competitions.myCompetitions()).thenAnswer((_) async => []);
  when(
    () => players.currentPlayers(_competitionId),
  ).thenAnswer((_) async => []);
  when(() => players.watch(any())).thenAnswer((_) => const Stream.empty());
  when(
    () => matches.feed(competitionId: _competitionId, limit: 20),
  ).thenAnswer((_) async => []);
  when(
    () => matches.seasonGameTypes(_competitionId),
  ).thenAnswer((_) async => const <GameType>{});
  when(
    () => matches.watch(_competitionId),
  ).thenAnswer((_) => const Stream.empty());

  final seasonStart = DateTime.utc(2026, 8, 1);
  final seasonEnd = DateTime.utc(2026, 9, 1);
  when(() => leaderboard.currentSeason(_competitionId)).thenAnswer(
    (_) async =>
        SeasonWindow(id: 's1', startsAt: seasonStart, endsAt: seasonEnd),
  );
  when(
    () =>
        leaderboard.leaderboards(competitionId: _competitionId, seasonId: 's1'),
  ).thenAnswer((_) async => []);
  when(
    () => leaderboard.watchLeaderboards(
      competitionId: _competitionId,
      seasonId: 's1',
    ),
  ).thenAnswer((_) => const Stream.empty());
  when(
    () => leaderboard.watchPlayers(competitionId: _competitionId),
  ).thenAnswer((_) => const Stream.empty());
  when(() => leaderboard.medals(_competitionId)).thenAnswer((_) async => []);

  final authBloc = AuthBloc(auth);
  final gameTypeFilterCubit = GameTypeFilterCubit();
  addTearDown(authBloc.close);
  addTearDown(gameTypeFilterCubit.close);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _CompetitionsStub()),
      ShellRoute(
        builder: (context, state, child) {
          final id = state.pathParameters['id']!;
          return CompetitionScope(
            competitionId: id,
            child: KeyedSubtree(
              key: ValueKey(id),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => PlayersCubit(players, id)),
                ],
                child: child,
              ),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/competition/:id',
            redirect: (context, state) =>
                state.matchedLocation == state.uri.path
                ? '${state.matchedLocation}/leaderboard'
                : null,
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, navigationShell) => CompetitionShell(
                  competitionId: state.pathParameters['id']!,
                  navigationShell: navigationShell,
                ),
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'leaderboard',
                        builder: (context, state) => BlocProvider(
                          create: (_) => LeaderboardCubit(
                            leaderboard,
                            state.pathParameters['id']!,
                          ),
                          child: LeaderboardPage(
                            competitionId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'matches',
                        builder: (context, state) => BlocProvider(
                          create: (_) => MatchListCubit(
                            matches,
                            gameTypeFilterCubit,
                            state.pathParameters['id']!,
                          ),
                          child: MatchesPage(
                            competitionId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'competitions',
                        builder: (_, _) => const CompetitionsPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => CompetitionCubit(competitions, authBloc)),
        BlocProvider(
          create: (_) => CompetitionListCubit(competitions, authBloc),
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

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('tapping the competition name switches to the competitions tab', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    await _pumpHarness(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LeaderboardPage)),
    );
    expect(find.text(l10n.competitionSettings), findsNothing);

    await tester.tap(find.text('Office Table Tennis'));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionsPage), findsOneWidget);
    expect(find.byType(_CompetitionsStub), findsNothing);
    expect(find.byType(CompetitionTabBar), findsOneWidget);
    expect(
      tester.widget<CompetitionTabBar>(find.byType(CompetitionTabBar)).current,
      CompetitionTab.competitions,
    );
    expect(find.text(l10n.competitionSettings), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders one shared tab bar across both tabs', (tester) async {
    AppPlatform.debugOverrideCupertino = false;
    await _pumpHarness(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LeaderboardPage)),
    );
    expect(find.byType(CompetitionTabBar), findsOneWidget);

    await tester.tap(find.text(l10n.matchesTitle).last);
    await tester.pumpAndSettle();

    expect(find.byType(MatchesPage), findsOneWidget);
    expect(find.byType(CompetitionTabBar), findsOneWidget);
  });

  testWidgets(
    'the competitions tab keeps the tab bar and the new match action',
    (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      await _pumpHarness(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LeaderboardPage)),
      );
      expect(_floatingActionLabel(tester), l10n.matchNew);

      await tester.tap(find.text(l10n.competitionsTitle).last);
      await tester.pumpAndSettle();

      expect(find.byType(CompetitionsPage), findsOneWidget);
      expect(find.byType(CompetitionTabBar), findsOneWidget);
      expect(
        tester
            .widget<CompetitionTabBar>(find.byType(CompetitionTabBar))
            .current,
        CompetitionTab.competitions,
      );
      expect(_floatingActionLabel(tester), l10n.matchNew);
    },
  );

  testWidgets('signing out while the leaderboard is open does not throw', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    final userChanges = StreamController<AuthUser?>();
    addTearDown(userChanges.close);

    await _pumpHarness(tester, userChanges: userChanges);
    expect(find.byType(LeaderboardPage), findsOneWidget);

    userChanges.add(null);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

String _floatingActionLabel(WidgetTester tester) {
  return tester
      .widget<AdaptiveFloatingAction>(find.byType(AdaptiveFloatingAction))
      .semanticLabel;
}

class _CompetitionsStub extends StatelessWidget {
  const _CompetitionsStub();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Competitions')));
}
