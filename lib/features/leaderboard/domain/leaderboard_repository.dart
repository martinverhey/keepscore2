import 'leaderboard.model.dart';
import 'medals.model.dart';
import 'season.model.dart';
import 'season_leaderboard.model.dart';
import 'season_window.model.dart';

abstract interface class LeaderboardRepository {
  Future<SeasonWindow> currentSeason(String competitionId, {DateTime? at});

  Future<List<Leaderboard>> leaderboards({
    required String competitionId,
    required String? seasonId,
  });

  Stream<void> watchLeaderboards({
    required String competitionId,
    required String? seasonId,
  });

  Future<List<Season>> finishedSeasons(String competitionId);

  Future<List<SeasonLeaderboard>> history({
    required String competitionId,
    String? seasonId,
    String? playerId,
  });

  Future<List<Medals>> medals(String competitionId);
}
