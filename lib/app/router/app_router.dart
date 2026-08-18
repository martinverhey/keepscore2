import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/recent_competition_store.dart';
import '../../core/error/failure.dart';
import '../../core/widgets/adaptive/adaptive.dart';
import '../../features/auth/presentation/cubit/auth_bloc.dart';
import '../../features/auth/presentation/cubit/sign_in_cubit.dart';
import '../../features/auth/presentation/pages/sign_in.page.dart';
import '../../features/auth/presentation/pages/upgrade_account.page.dart';
import '../../features/competition/domain/competition_repository.dart';
import '../../features/competition/presentation/cubit/competition_cubit.dart';
import '../../features/competition/presentation/cubit/competition_list_cubit.dart';
import '../../features/competition/presentation/cubit/create_competition_cubit.dart';
import '../../features/competition/presentation/cubit/join_competition_cubit.dart';
import '../../features/competition/presentation/pages/competition_content.page.dart';
import '../../features/competition/presentation/pages/competitions.page.dart';
import '../../features/competition/presentation/pages/create_competition.page.dart';
import '../../features/competition/presentation/pages/join_competition.page.dart';
import '../../features/competition/presentation/widgets/home_sidebar_competition.dart';
import '../../features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../features/match/presentation/cubit/match_detail_cubit.dart';
import '../../features/match/presentation/cubit/match_form_cubit.dart';
import '../../features/match/presentation/cubit/match_list_cubit.dart';
import '../../features/match/presentation/pages/match_detail.page.dart';
import '../../features/match/presentation/pages/new_match.page.dart';
import '../../features/player/presentation/cubit/players_cubit.dart';
import '../../features/player/presentation/pages/players.page.dart';
import '../../features/settings/presentation/cubit/configuration_cubit.dart';
import '../../features/settings/presentation/cubit/history_cubit.dart';
import '../../features/settings/presentation/pages/settings.page.dart';
import '../../features/settings/presentation/pages/configuration.page.dart';
import '../../features/settings/presentation/pages/history.page.dart';
import '../../features/settings/presentation/pages/theme.page.dart';
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
  static const theme = '/settings/theme';

  static String competition(String id) => '/competition/$id';
  static String settings(String id) => '/competition/$id/settings';
  static String configuration(String id) =>
      '/competition/$id/settings/configuration';
  static String players(String id) => '/competition/$id/settings/players';
  static String history(String id) => '/competition/$id/settings/history';
  static String newMatch(String id) => '/competition/$id/match/new';
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

      try {
        final overview = await getIt<CompetitionRepository>().overview(
          recentId,
        );
        if (overview == null) {
          await RecentCompetitionStore.clear();
          return null;
        }
        return Routes.competition(recentId);
      } on Failure {
        return null;
      }
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
        path: Routes.home,
        pageBuilder: (context, state) => adaptivePage(
          context,
          child: BlocProvider(
            create: (_) => getIt<CompetitionListCubit>(),
            child: CompetitionsPage(
              sidebarCompetition: switch (state.extra) {
                final HomeSidebarCompetition extra => extra,
                _ => null,
              },
            ),
          ),
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
      GoRoute(
        path: Routes.theme,
        pageBuilder: (context, state) => adaptivePage(
          context,
          child: ThemePage(
            sidebarCompetition: switch (state.extra) {
              final HomeSidebarCompetition extra => extra,
              _ => null,
            },
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final id = state.pathParameters['id']!;
          return KeyedSubtree(
            key: ValueKey(id),
            child: BlocProvider(
              create: (_) => getIt<CompetitionCubit>(param1: id)..load(),
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/competition/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return KeyedSubtree(
                key: ValueKey(id),
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => getIt<PlayersCubit>(param1: id),
                    ),
                    BlocProvider(
                      create: (_) => getIt<MatchListCubit>(param1: id),
                    ),
                    BlocProvider(
                      create: (_) => getIt<LeaderboardCubit>(param1: id),
                    ),
                  ],
                  child: CompetitionContent(competitionId: id),
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'settings',
                pageBuilder: (context, state) => adaptivePage(
                  context,
                  child: SettingsPage(
                    competitionId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'configuration',
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
                    path: 'players',
                    pageBuilder: (context, state) => adaptivePage(
                      context,
                      child: BlocProvider(
                        create: (_) => getIt<PlayersCubit>(
                          param1: state.pathParameters['id']!,
                        ),
                        child: const PlayersPage(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'history',
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
              GoRoute(
                path: 'match/new',
                pageBuilder: (context, state) => adaptiveModalPage<bool>(
                  context,
                  child: BlocProvider(
                    create: (_) => getIt<MatchFormCubit>(
                      param1: state.pathParameters['id']!,
                    ),
                    child: const NewMatchPage(),
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
  );
}
