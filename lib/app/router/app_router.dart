import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/recent_competition_store.dart';
import '../../core/widgets/adaptive/adaptive.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/sign_in_cubit.dart';
import '../../features/auth/presentation/pages/sign_in.page.dart';
import '../../features/auth/presentation/pages/upgrade_account.page.dart';
import '../../features/competition/presentation/cubit/competition_list_cubit.dart';
import '../../features/competition/presentation/pages/competition_shell.dart';
import '../../features/competition/presentation/pages/welcome.page.dart';
import '../../features/competition/presentation/widgets/competition_scope.dart';
import '../../features/competition/presentation/widgets/sidebar_shell.dart';
import '../../features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../features/leaderboard/presentation/pages/leaderboard.page.dart';
import '../../features/match/presentation/cubit/match_list_cubit.dart';
import '../../features/match/presentation/pages/matches.page.dart';
import '../../features/player/presentation/cubit/players_cubit.dart';
import '../../features/settings/presentation/cubit/history_cubit.dart';
import '../../features/settings/presentation/pages/profile.page.dart';
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
  static const language = '/settings/language';

  static String competition(String id) => '/competition/$id';
  static String leaderboard(String id) => '/competition/$id/leaderboard';
  static String matches(String id) => '/competition/$id/matches';
  static String profile(String id) => '/competition/$id/profile';
  static String history(String id) => '/competition/$id/settings/history';
}

Future<String?> resolveHomeTarget(CompetitionListCubit competitions) async {
  await competitions.ensureLoaded();
  final state = competitions.state;
  if (state is! CompetitionListReady) return null;

  final recentId = await RecentCompetitionStore.get();
  if (recentId != null) {
    if (competitions.isMember(recentId)) return Routes.competition(recentId);
    await RecentCompetitionStore.clear();
  }

  if (state.competitions.isEmpty) return null;
  return Routes.competition(state.competitions.first.id);
}

GoRouter createRouter(AuthCubit authCubit) {
  Future<String?>? pendingHomeTarget;

  Future<String?> resolveHomeTargetOnce() {
    final future = pendingHomeTarget ??= resolveHomeTarget(
      getIt<CompetitionListCubit>(),
    );
    future.whenComplete(() => pendingHomeTarget = null);
    return future;
  }

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) async {
      final session = authCubit.state;
      final location = state.matchedLocation;

      if (session is AuthUnknown) {
        return location == Routes.splash ? null : Routes.splash;
      }

      if (!session.isAuthenticated) {
        return location == Routes.signIn ? null : Routes.signIn;
      }

      final isEntryPoint =
          location == Routes.signIn || location == Routes.splash;

      if (isEntryPoint || location == Routes.home) {
        final target = await resolveHomeTargetOnce();
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
      ShellRoute(
        builder: (context, state, child) =>
            SidebarShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) =>
                adaptivePage(context, child: const WelcomePage()),
          ),
          GoRoute(
            path: Routes.language,
            pageBuilder: (context, state) =>
                adaptivePage(context, child: const LanguagePage()),
          ),
          GoRoute(
            path: Routes.upgradeAccount,
            pageBuilder: (context, state) => adaptivePage(
              context,
              child: BlocProvider(
                create: (_) => getIt<SignInCubit>(param1: SignInMode.upgrade),
                child: const UpgradeAccountPage(),
              ),
            ),
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
                                    getIt<LeaderboardCubit>(param1: id),
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
                                create: (_) =>
                                    getIt<MatchListCubit>(param1: id),
                                child: MatchesPage(competitionId: id),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) =>
                        adaptivePage(context, child: const ProfilePage()),
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
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
