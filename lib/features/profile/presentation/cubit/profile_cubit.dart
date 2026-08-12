import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../domain/profile_repository.dart';
import 'profile_state.dart';

export 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(
    this._leaderboardRepository,
    this._profileRepository,
    this.competitionId,
    this.playerId,
  ) : super(const ProfileState());

  final LeaderboardRepository _leaderboardRepository;
  final ProfileRepository _profileRepository;
  final String competitionId;
  final String playerId;

  Future<void> load() async {
    emit(const ProfileState());
    try {
      final season = await _leaderboardRepository.currentSeason(competitionId);
      if (isClosed) return;

      if (season.id == null) {
        emit(const ProfileState(status: ProfileStatus.ready));
        return;
      }

      final standings = await _leaderboardRepository.standings(
        competitionId: competitionId,
        seasonId: season.id,
      );
      if (isClosed) return;

      final history = await _profileRepository.ratingHistory(
        seasonId: season.id!,
        playerId: playerId,
      );
      if (isClosed) return;

      Leaderboard? mine;
      for (final standing in standings) {
        if (standing.playerId == playerId) {
          mine = standing;
          break;
        }
      }

      emit(
        ProfileState(
          status: ProfileStatus.ready,
          standing: mine,
          playerCount: standings.length,
          history: history,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileState(status: ProfileStatus.failed, failure: failure));
    }
  }
}
