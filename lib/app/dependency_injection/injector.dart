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
import '../../features/competition/presentation/cubit/history_cubit.dart';
import '../../features/competition/presentation/cubit/join_competition_cubit.dart';
import '../../features/leaderboard/data/supabase_leaderboard_repository.dart';
import '../../features/leaderboard/domain/leaderboard_repository.dart';
import '../../features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../features/match/data/supabase_match_repository.dart';
import '../../features/match/domain/match_repository.dart';
import '../../features/match/presentation/cubit/game_type_filter_cubit.dart';
import '../../features/match/presentation/cubit/match_detail_cubit.dart';
import '../../features/match/presentation/cubit/match_form_cubit.dart';
import '../../features/match/presentation/cubit/match_list_cubit.dart';
import '../../features/player/data/supabase_player_repository.dart';
import '../../features/player/domain/player_repository.dart';
import '../../features/player/presentation/cubit/players_cubit.dart';
import '../../features/profile/data/supabase_profile_repository.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/profile/presentation/cubit/profile_history_cubit.dart';
import '../../features/profile/presentation/cubit/profile_overview_cubit.dart';
import '../../features/profile/presentation/cubit/profile_versus_cubit.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';

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
    ..registerFactoryParam<HistoryCubit, String, void>(
      (competitionId, _) =>
          HistoryCubit(getIt<LeaderboardRepository>(), competitionId),
    )
    ..registerLazySingleton<LeaderboardRepository>(
      () => SupabaseLeaderboardRepository(getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<MatchRepository>(
      () => SupabaseMatchRepository(getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<GameTypeFilterCubit>(() => GameTypeFilterCubit())
    ..registerFactoryParam<LeaderboardCubit, String, void>(
      (competitionId, _) => LeaderboardCubit(
        getIt<LeaderboardRepository>(),
        getIt<GameTypeFilterCubit>(),
        competitionId,
      ),
    )
    ..registerFactoryParam<MatchListCubit, String, void>(
      (competitionId, _) => MatchListCubit(
        getIt<MatchRepository>(),
        getIt<GameTypeFilterCubit>(),
        competitionId,
      ),
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
    ..registerFactoryParam<MatchDetailCubit, String, String>(
      (matchId, competitionId) => MatchDetailCubit(
        getIt<MatchRepository>(),
        getIt<CompetitionRepository>(),
        matchId,
        competitionId,
      ),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => SupabaseProfileRepository(getIt<SupabaseClient>()),
    )
    ..registerFactoryParam<ProfileOverviewCubit, String, String>(
      (competitionId, playerId) => ProfileOverviewCubit(
        getIt<LeaderboardRepository>(),
        getIt<ProfileRepository>(),
        getIt<MatchRepository>(),
        getIt<GameTypeFilterCubit>(),
        competitionId,
        playerId,
      ),
    )
    ..registerFactoryParam<ProfileVersusCubit, String, String>(
      (playerId, opponentId) => ProfileVersusCubit(
        getIt<ProfileRepository>(),
        getIt<MatchRepository>(),
        getIt<GameTypeFilterCubit>(),
        playerId,
        opponentId,
      ),
    )
    ..registerFactoryParam<ProfileHistoryCubit, String, String>(
      (competitionId, playerId) => ProfileHistoryCubit(
        getIt<LeaderboardRepository>(),
        getIt<GameTypeFilterCubit>(),
        competitionId,
        playerId,
      ),
    )
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit());
}
