import '../../match/domain/game_type.enum.dart';
import 'leaderboard.model.dart';
import 'medals.model.dart';
import 'season_standing.model.dart';
import 'season_window.model.dart';

abstract interface class LeaderboardRepository {
  Future<SeasonWindow> currentSeason(String competitionId, {DateTime? at});

  Future<List<Leaderboard>> standings({
    required String competitionId,
    required String? seasonId,
    GameType? gameType,
  });

  Stream<void> watchStandings({
    required String competitionId,
    required String? seasonId,
    GameType? gameType,
  });

  Future<List<SeasonStanding>> seasonHistory({
    required String competitionId,
    String? playerId,
    GameType? gameType,
  });

  Future<List<Medals>> medals(String competitionId);
}
