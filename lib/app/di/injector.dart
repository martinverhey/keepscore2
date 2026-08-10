import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_bloc.dart';
import '../../features/auth/presentation/cubit/sign_in_cubit.dart';
import '../../features/competition/data/supabase_competition_repository.dart';
import '../../features/competition/domain/competition_repository.dart';
import '../../features/competition/presentation/cubit/competition_detail_cubit.dart';
import '../../features/competition/presentation/cubit/competition_list_cubit.dart';
import '../../features/competition/presentation/cubit/competition_settings_cubit.dart';
import '../../features/competition/presentation/cubit/create_competition_cubit.dart';
import '../../features/competition/presentation/cubit/join_competition_cubit.dart';
import '../../features/leaderboard/data/supabase_leaderboard_repository.dart';
import '../../features/leaderboard/domain/leaderboard_repository.dart';
import '../../features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../features/match/data/supabase_match_repository.dart';
import '../../features/match/domain/match_repository.dart';
import '../../features/match/presentation/cubit/match_detail_cubit.dart';
import '../../features/match/presentation/cubit/match_form_cubit.dart';
import '../../features/match/presentation/cubit/match_list_cubit.dart';
import '../../features/player/data/supabase_player_repository.dart';
import '../../features/player/domain/player_repository.dart';
import '../../features/player/presentation/cubit/players_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
    ..registerLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()))
    ..registerFactoryParam<SignInCubit, SignInMode, void>(
      (mode, _) => SignInCubit(getIt<AuthRepository>(), mode: mode),
    )
    ..registerLazySingleton<CompetitionRepository>(
      () => SupabaseCompetitionRepository(getIt<SupabaseClient>()),
    )
    ..registerFactory<CompetitionListCubit>(
      () => CompetitionListCubit(getIt<CompetitionRepository>()),
    )
    ..registerFactory<CreateCompetitionCubit>(
      () => CreateCompetitionCubit(getIt<CompetitionRepository>()),
    )
    ..registerFactory<JoinCompetitionCubit>(
      () => JoinCompetitionCubit(getIt<CompetitionRepository>()),
    )
    ..registerLazySingleton<PlayerRepository>(
      () => SupabasePlayerRepository(getIt<SupabaseClient>()),
    )
    ..registerFactoryParam<CompetitionDetailCubit, String, void>(
      (competitionId, _) =>
          CompetitionDetailCubit(getIt<CompetitionRepository>(), competitionId),
    )
    ..registerFactoryParam<CompetitionSettingsCubit, String, void>(
      (competitionId, _) => CompetitionSettingsCubit(
        getIt<CompetitionRepository>(),
        competitionId,
      ),
    )
    ..registerFactoryParam<PlayersCubit, String, void>(
      (competitionId, _) =>
          PlayersCubit(getIt<PlayerRepository>(), competitionId),
    )
    ..registerLazySingleton<LeaderboardRepository>(
      () => SupabaseLeaderboardRepository(getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<MatchRepository>(
      () => SupabaseMatchRepository(getIt<SupabaseClient>()),
    )
    ..registerFactoryParam<LeaderboardCubit, String, void>(
      (competitionId, _) =>
          LeaderboardCubit(getIt<LeaderboardRepository>(), competitionId),
    )
    ..registerFactoryParam<MatchListCubit, String, void>(
      (competitionId, _) =>
          MatchListCubit(getIt<MatchRepository>(), competitionId),
    )
    ..registerFactoryParam<MatchFormCubit, String, void>(
      (competitionId, _) => MatchFormCubit(
        getIt<MatchRepository>(),
        getIt<CompetitionRepository>(),
        getIt<PlayerRepository>(),
        getIt<LeaderboardRepository>(),
        competitionId,
      ),
    )
    // Two ids: the match to show, and the competition it belongs to — the
    // page needs the owner to know whether this user may delete it.
    ..registerFactoryParam<MatchDetailCubit, String, String>(
      (matchId, competitionId) => MatchDetailCubit(
        getIt<MatchRepository>(),
        getIt<CompetitionRepository>(),
        matchId,
        competitionId,
      ),
    );
}
