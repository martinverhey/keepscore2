import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/core/data/recent_competition_store.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competition_shell.dart';
import 'package:keepscore2/features/competition/presentation/pages/competitions.page.dart';
import 'package:keepscore2/features/competition/presentation/widgets/active_competition_card.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_scope.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_tab_bar.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/leaderboard/presentation/widgets/leaderboard.page.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:keepscore2/features/match/presentation/widgets/matches.page.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
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

CompetitionOverview _overview(String id, String name) => CompetitionOverview(
  competition: Competition(
    id: id,
    joinCode: id.toUpperCase().padRight(6, 'X'),
    name: name,
    ownerId: 'owner-$id',
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
  myPlayerId: 'player-$id',
);

Leaderboard _row(String id, String displayName) => Leaderboard(
  seasonId: 'season-$id',
  competitionId: id,
  playerId: 'player-$id',
  displayName: displayName,
  isClaimed: true,
  isOwner: false,
  rating: 1200,
  played: 3,
  wins: 2,
  losses: 1,
  draws: 0,
  rank: 1,
);

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('leaving the competition you are standing in exits its shell', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = MockAuthRepository();
    final competitions = MockCompetitionRepository();
    final players = MockPlayerRepository();
    final matches = MockMatchRepository();
    final leaderboard = MockLeaderboardRepository();

    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

    final memberships = [
      _overview('c1', 'Office Table Tennis'),
      _overview('c2', 'Padel Ladder'),
    ];
    when(
      () => competitions.myCompetitions(),
    ).thenAnswer((_) async => List.of(memberships));
    when(
      () => competitions.overview('c1'),
    ).thenAnswer((_) async => _overview('c1', 'Office Table Tennis'));
    when(() => competitions.leave('c1')).thenAnswer((_) async {
      memberships.removeWhere((overview) => overview.id == 'c1');
    });

    when(() => players.watch('c1')).thenAnswer((_) => const Stream.empty());
    when(() => players.currentPlayers('c1')).thenAnswer(
      (_) async => [
        const Player(
          id: 'player-c1',
          competitionId: 'c1',
          displayName: 'Ada',
          isActive: true,
          userId: 'user-1',
        ),
      ],
    );
    when(
      () => matches.feed(competitionId: 'c1', limit: 20),
    ).thenAnswer((_) async => []);
    when(
      () => matches.seasonGameTypes('c1'),
    ).thenAnswer((_) async => const <GameType>{});
    when(() => matches.watch('c1')).thenAnswer((_) => const Stream.empty());
    when(() => leaderboard.currentSeason('c1')).thenAnswer(
      (_) async => SeasonWindow(
        id: 'season-c1',
        startsAt: DateTime.utc(2026, 8, 1),
        endsAt: DateTime.utc(2026, 9, 1),
      ),
    );
    when(
      () => leaderboard.leaderboards(
        competitionId: 'c1',
        seasonId: 'season-c1',
      ),
    ).thenAnswer((_) async => [_row('c1', 'Ada One')]);
    when(
      () => leaderboard.watchLeaderboards(
        competitionId: 'c1',
        seasonId: 'season-c1',
      ),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => leaderboard.watchPlayers(competitionId: 'c1'),
    ).thenAnswer((_) => const Stream.empty());
    when(() => leaderboard.medals('c1')).thenAnswer((_) async => []);

    final authBloc = AuthBloc(auth);
    final gameTypeFilterCubit = GameTypeFilterCubit();
    final competitionCubit = CompetitionCubit(competitions, authBloc);
    addTearDown(authBloc.close);
    addTearDown(gameTypeFilterCubit.close);
    addTearDown(competitionCubit.close);

    final router = _buildRouter(
      playerRepository: players,
      matchRepository: matches,
      leaderboardRepository: leaderboard,
      gameTypeFilterCubit: gameTypeFilterCubit,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<CompetitionCubit>.value(value: competitionCubit),
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

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LeaderboardPage)),
    );
    expect(find.byType(CompetitionTabBar), findsOneWidget);
    expect(await RecentCompetitionStore.get(), 'c1');

    await tester.tap(find.text('Office Table Tennis'));
    await tester.pumpAndSettle();
    expect(find.byType(CompetitionsPage), findsOneWidget);
    expect(find.byType(CompetitionTabBar), findsOneWidget);

    final manage = find.descendant(
      of: find.byType(ActiveCompetitionCard),
      matching: find.text(l10n.competitionManage),
    );
    await tester.tap(manage);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.competitionLeave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.competitionLeave));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionTabBar), findsNothing);
    expect(find.byType(CompetitionsPage), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/',
    );
    expect(competitionCubit.competitionId, isNull);
    expect(await RecentCompetitionStore.get(), isNull);
    expect(find.text('Office Table Tennis'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

GoRouter _buildRouter({
  required PlayerRepository playerRepository,
  required MatchRepository matchRepository,
  required LeaderboardRepository leaderboardRepository,
  required GameTypeFilterCubit gameTypeFilterCubit,
}) {
  return GoRouter(
    initialLocation: '/competition/c1/leaderboard',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            adaptivePage(context, child: const CompetitionsPage()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) {
          final id = state.pathParameters['id']!;
          return adaptivePageNoWebTransition<void>(
            child: CompetitionScope(
              competitionId: id,
              child: KeyedSubtree(
                key: ValueKey(id),
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => PlayersCubit(playerRepository, id),
                    ),
                  ],
                  child: child,
                ),
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
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return BlocProvider(
                            key: ValueKey(id),
                            create: (_) =>
                                LeaderboardCubit(leaderboardRepository, id),
                            child: LeaderboardPage(competitionId: id),
                          );
                        },
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'matches',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return BlocProvider(
                            key: ValueKey(id),
                            create: (_) => MatchListCubit(
                              matchRepository,
                              gameTypeFilterCubit,
                              id,
                            ),
                            child: MatchesPage(competitionId: id),
                          );
                        },
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
}
