import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/recent_competition_store.dart';
import '../../core/widgets/adaptive/adaptive.dart';
import '../../features/auth/presentation/cubit/auth_bloc.dart';
import '../../features/auth/presentation/cubit/sign_in_cubit.dart';
import '../../features/auth/presentation/pages/sign_in.page.dart';
import '../../features/auth/presentation/pages/upgrade_account.page.dart';
import '../../features/competition/presentation/cubit/competition_list_cubit.dart';
import '../../features/competition/presentation/cubit/create_competition_cubit.dart';
import '../../features/competition/presentation/cubit/join_competition_cubit.dart';
import '../../features/competition/presentation/pages/competition_shell.dart';
import '../../features/competition/presentation/pages/competitions.page.dart';
import '../../features/competition/presentation/pages/create_competition.page.dart';
import '../../features/competition/presentation/pages/join_competition.page.dart';
import '../../features/competition/presentation/widgets/competition_scope.dart';
import '../../features/competition/presentation/widgets/sidebar_shell.dart';
import '../../features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../features/leaderboard/presentation/widgets/leaderboard.page.dart';
import '../../features/match/presentation/cubit/match_detail_cubit.dart';
import '../../features/match/presentation/cubit/match_list_cubit.dart';
import '../../features/match/presentation/pages/match_detail.page.dart';
import '../../features/match/presentation/widgets/matches.page.dart';
import '../../features/player/presentation/cubit/players_cubit.dart';
import '../../features/player/presentation/pages/players.page.dart';
import '../../features/settings/presentation/cubit/configuration_cubit.dart';
import '../../features/settings/presentation/cubit/history_cubit.dart';
import '../../features/settings/presentation/pages/settings.page.dart';
import '../../features/settings/presentation/pages/configuration.page.dart';
import '../../features/settings/presentation/pages/history.page.dart';
import '../../features/settings/presentation/pages/language.page.dart';
import '../dependency_injection/injector.dart';
import '../splash.page.dart';
import 'go_router_refresh_stream.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const upgradeAccount = '/upgrade';
  static const home = '/';
  static const createCompetition = '/create';
  static const joinCompetition = '/join';
  static const language = '/settings/language';

  static String competition(String id) => '/competition/$id';
  static String leaderboard(String id) => '/competition/$id/leaderboard';
  static String matches(String id) => '/competition/$id/matches';
  static String settings(String id) => '/competition/$id/settings';
  static String configuration(String id) =>
      '/competition/$id/settings/configuration';
  static String players(String id) => '/competition/$id/settings/players';
  static String history(String id) => '/competition/$id/settings/history';
  static String match(String id, String matchId) =>
      '/competition/$id/match/$matchId';
}

GoRouter createRouter(AuthBloc authBloc) {
  Future<String?>? pendingRecentCompetitionTarget;
  var recentCompetitionResolvedOnce = false;

  // Resolves to a competition route only once membership is confirmed, so a
  // stale id (left the competition, or a guest's anonymous session was
  // replaced by a new one) never gets a chance to render the competition
  // shell before bouncing back to Routes.home — it goes straight there.
  Future<String?> resolveRecentCompetitionTarget() {
    final future = pendingRecentCompetitionTarget ??= () async {
      final recentId = await RecentCompetitionStore.get();
      if (recentId == null) return null;

      final competitions = getIt<CompetitionListCubit>();
      await competitions.ensureLoaded();
      if (competitions.state is! CompetitionListReady) return null;
      if (competitions.isMember(recentId)) return Routes.competition(recentId);

      await RecentCompetitionStore.clear();
      return null;
    }();
    future.whenComplete(() {
      pendingRecentCompetitionTarget = null;
      recentCompetitionResolvedOnce = true;
    });
    return future;
  }

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) async {
      final session = authBloc.state;
      final location = state.matchedLocation;

      if (session.status == AuthStatus.unknown) {
        return location == Routes.splash ? null : Routes.splash;
      }

      if (!session.isAuthenticated) {
        return location == Routes.signIn ? null : Routes.signIn;
      }

      final isEntryPoint =
          location == Routes.signIn || location == Routes.splash;
      final isUnsettledHome =
          location == Routes.home &&
          (pendingRecentCompetitionTarget != null ||
              !recentCompetitionResolvedOnce);

      if (isEntryPoint || isUnsettledHome) {
        final target = await resolveRecentCompetitionTarget();
        if (target != null) return target;
        return location == Routes.home ? null : Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SignInCubit>(param1: SignInMode.signIn),
          child: const SignInPage(),
        ),
      ),
      GoRoute(
        path: Routes.upgradeAccount,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SignInCubit>(param1: SignInMode.upgrade),
          child: const UpgradeAccountPage(),
        ),
      ),
      GoRoute(
        path: Routes.createCompetition,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CreateCompetitionCubit>(),
          child: const CreateCompetitionPage(),
        ),
      ),
      GoRoute(
        path: Routes.joinCompetition,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<JoinCompetitionCubit>(),
          child: const JoinCompetitionPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            SidebarShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) =>
                adaptivePage(context, child: const CompetitionsPage()),
          ),
          GoRoute(
            path: Routes.language,
            pageBuilder: (context, state) =>
                adaptivePage(context, child: const LanguagePage()),
          ),
          ShellRoute(
            pageBuilder: (context, state, child) {
              final id = state.pathParameters['id']!;
              final content = CompetitionScope(
                competitionId: id,
                child: KeyedSubtree(
                  key: ValueKey(id),
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => getIt<PlayersCubit>(param1: id),
                      ),
                    ],
                    child: child,
                  ),
                ),
              );
              return adaptivePageNoWebTransition<void>(child: content);
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
                    builder: (context, state, navigationShell) =>
                        CompetitionShell(
                          competitionId: state.pathParameters['id']!,
                          child: navigationShell,
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
                                    getIt<LeaderboardCubit>(param1: id),
                                child: const LeaderboardPage(),
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
                                create: (_) =>
                                    getIt<MatchListCubit>(param1: id),
                                child: const MatchesPage(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'settings',
                    pageBuilder: (context, state) => adaptivePage(
                      context,
                      child: SettingsPage(
                        competitionId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'settings/configuration',
                    pageBuilder: (context, state) => adaptivePage(
                      context,
                      child: BlocProvider(
                        create: (_) => getIt<ConfigurationCubit>(
                          param1: state.pathParameters['id']!,
                        ),
                        child: const ConfigurationPage(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'settings/players',
                    pageBuilder: (context, state) =>
                        adaptivePage(context, child: const PlayersPage()),
                  ),
                  GoRoute(
                    path: 'settings/history',
                    pageBuilder: (context, state) => adaptivePage(
                      context,
                      child: BlocProvider(
                        create: (_) => getIt<HistoryCubit>(
                          param1: state.pathParameters['id']!,
                        ),
                        child: const HistoryPage(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'match/:matchId',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<MatchDetailCubit>(
                        param1: state.pathParameters['matchId']!,
                        param2: state.pathParameters['id']!,
                      ),
                      child: const MatchDetailPage(),
                    ),
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
