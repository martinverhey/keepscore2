import 'leaderboard.dart';
import 'season.dart';
import 'season_window.dart';

abstract interface class LeaderboardRepository {
  Future<SeasonWindow> currentSeason(String competitionId, {DateTime? at});

  Future<List<Season>> seasons(String competitionId);

  Future<List<Leaderboard>> standings({
    required String competitionId,
    required String? seasonId,
  });

  Stream<void> watchStandings({
    required String competitionId,
    required String? seasonId,
  });
}
