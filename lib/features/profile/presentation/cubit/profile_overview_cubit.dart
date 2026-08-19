import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/leaderboard_repository.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../match/domain/match_repository.dart';
import '../../domain/profile_repository.dart';
import '../../domain/rating_point.model.dart';
import 'profile_overview_state.dart';

export 'profile_overview_state.dart';

class ProfileOverviewCubit extends Cubit<ProfileOverviewState> {
  ProfileOverviewCubit(
    this._leaderboardRepository,
    this._profileRepository,
    this._matchRepository,
    this.competitionId,
    this.playerId,
  ) : super(const ProfileOverviewLoading());

  final LeaderboardRepository _leaderboardRepository;
  final ProfileRepository _profileRepository;
  final MatchRepository _matchRepository;
  final String competitionId;
  final String playerId;

  Future<void> load({String? viewerPlayerId}) async {
    emit(const ProfileOverviewLoading());
    final hasOpponent = viewerPlayerId != null && viewerPlayerId != playerId;
    try {
      final window = await _leaderboardRepository.currentSeason(competitionId);
      if (isClosed) return;
      final seasonId = window.id;

      final statsFuture = _profileRepository.profileStats(
        playerId: playerId,
        seasonId: seasonId,
      );
      final recentMatchesFuture = _matchRepository.recentForPlayer(
        playerId: playerId,
      );
      final allMedalsFuture = _leaderboardRepository.medals(competitionId);
      final leaderboardsFuture = seasonId == null
          ? null
          : _leaderboardRepository.leaderboards(
              competitionId: competitionId,
              seasonId: seasonId,
            );
      final ratingHistoryFuture = seasonId == null
          ? null
          : _profileRepository.ratingHistory(
              seasonId: seasonId,
              playerId: playerId,
            );

      final stats = await statsFuture;
      final recentMatches = await recentMatchesFuture;
      final allMedals = await allMedalsFuture;
      if (isClosed) return;

      Medals? medals;
      for (final tally in allMedals) {
        if (tally.playerId == playerId) {
          medals = tally;
          break;
        }
      }

      Leaderboard? mine;
      var playerCount = 0;
      var history = const <RatingPoint>[];

      if (seasonId != null) {
        final leaderboards = await leaderboardsFuture!;
        history = await ratingHistoryFuture!;
        if (isClosed) return;

        playerCount = leaderboards.length;
        for (final leaderboard in leaderboards) {
          if (leaderboard.playerId == playerId) {
            mine = leaderboard;
            break;
          }
        }
      }

      emit(
        ProfileOverviewReady(
          leaderboard: mine,
          medals: medals,
          bestRating: stats.bestRating,
          playerCount: playerCount,
          history: history,
          totalPlayed: stats.totalPlayed,
          streak: stats.streak,
          bestStreaks: stats.bestStreaks,
          recentPlayed: stats.recentPlayed,
          recentMatches: recentMatches,
          hasOpponent: hasOpponent,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ProfileOverviewFailed(failure));
    }
  }
}
