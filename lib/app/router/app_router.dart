import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/sign_in_cubit.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/upgrade_account_page.dart';
import '../../features/competition/presentation/bloc/competition_detail_cubit.dart';
import '../../features/competition/presentation/bloc/competition_list_cubit.dart';
import '../../features/competition/presentation/bloc/competition_settings_cubit.dart';
import '../../features/competition/presentation/bloc/create_competition_cubit.dart';
import '../../features/competition/presentation/bloc/join_competition_cubit.dart';
import '../../features/competition/presentation/pages/competition_detail_page.dart';
import '../../features/competition/presentation/pages/competition_settings_page.dart';
import '../../features/competition/presentation/pages/competitions_page.dart';
import '../../features/competition/presentation/pages/create_competition_page.dart';
import '../../features/competition/presentation/pages/join_competition_page.dart';
import '../../features/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import '../../features/match/presentation/bloc/match_detail_cubit.dart';
import '../../features/match/presentation/bloc/match_form_cubit.dart';
import '../../features/match/presentation/bloc/match_list_cubit.dart';
import '../../features/match/presentation/pages/match_detail_page.dart';
import '../../features/match/presentation/pages/new_match_page.dart';
import '../../features/player/presentation/bloc/players_cubit.dart';
import '../di/injector.dart';
import '../splash_page.dart';
import 'go_router_refresh_stream.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const upgradeAccount = '/upgrade';
  static const home = '/';
  static const createCompetition = '/create';
  static const joinCompetition = '/join';

  static String competition(String id) => '/c/$id';

  static String competitionSettings(String id) => '/c/$id/settings';

  static String newMatch(String id) => '/c/$id/match/new';

  static String match(String id, String matchId) => '/c/$id/match/$matchId';
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final session = authBloc.state;
      final location = state.matchedLocation;

      if (session.status == AuthStatus.unknown) {
        return location == Routes.splash ? null : Routes.splash;
      }

      if (!session.isAuthenticated) {
        return location == Routes.signIn ? null : Routes.signIn;
      }

      if (location == Routes.signIn || location == Routes.splash) {
        return Routes.home;
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
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CompetitionListCubit>(),
          child: const CompetitionsPage(),
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
        path: '/c/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<CompetitionDetailCubit>(param1: id),
              ),
              BlocProvider(create: (_) => getIt<PlayersCubit>(param1: id)),
              BlocProvider(create: (_) => getIt<MatchListCubit>(param1: id)),
              BlocProvider(create: (_) => getIt<LeaderboardCubit>(param1: id)),
            ],
            child: CompetitionDetailPage(competitionId: id),
          );
        },
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<CompetitionSettingsCubit>(
                param1: state.pathParameters['id']!,
              ),
              child: const CompetitionSettingsPage(),
            ),
          ),
          GoRoute(
            path: 'match/new',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<MatchFormCubit>(
                param1: state.pathParameters['id']!,
              ),
              child: const NewMatchPage(),
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
  );
}
