import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../domain/head_to_head_record.dart';
import '../../domain/profile_repository.dart';
import '../../domain/rating_point.dart';
import '../../domain/streak.dart';
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

  Future<void> load({String? viewerPlayerId}) async {
    emit(const ProfileState());
    try {
      final season = await _leaderboardRepository.currentSeason(competitionId);
      if (isClosed) return;

      final totalPlayed = await _profileRepository.totalMatchesPlayed(
        playerId: playerId,
      );
      final seasonHistory = await _leaderboardRepository.seasonHistory(
        competitionId: competitionId,
        playerId: playerId,
      );
      if (isClosed) return;

      Leaderboard? mine;
      var playerCount = 0;
      var history = const <RatingPoint>[];
      var streak = const Streak.none();

      if (season.id != null) {
        final standings = await _leaderboardRepository.standings(
          competitionId: competitionId,
          seasonId: season.id,
        );
        history = await _profileRepository.ratingHistory(
          seasonId: season.id!,
          playerId: playerId,
        );
        streak = await _profileRepository.currentStreak(
          seasonId: season.id!,
          playerId: playerId,
        );
        if (isClosed) return;

        playerCount = standings.length;
        for (final standing in standings) {
          if (standing.playerId == playerId) {
            mine = standing;
            break;
          }
        }
      }

      var headToHead = const <HeadToHeadRecord>[];
      if (viewerPlayerId != null && viewerPlayerId != playerId) {
        headToHead = await _profileRepository.headToHead(
          playerId: playerId,
          opponentId: viewerPlayerId,
        );
        if (isClosed) return;
      }

      emit(
        ProfileState(
          status: ProfileStatus.ready,
          standing: mine,
          playerCount: playerCount,
          history: history,
          totalPlayed: totalPlayed,
          streak: streak,
          seasonHistory: seasonHistory,
          headToHead: headToHead,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileState(status: ProfileStatus.failed, failure: failure));
    }
  }
}
