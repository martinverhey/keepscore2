import '../../match/domain/game_type.dart';
import 'leaderboard.dart';
import 'medal_tally.dart';
import 'season.dart';
import 'season_standing.dart';
import 'season_window.dart';

abstract interface class LeaderboardRepository {
  Future<SeasonWindow> currentSeason(String competitionId, {DateTime? at});

  Future<List<Season>> seasons(String competitionId);

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
  });

  Future<List<MedalTally>> medalTallies(String competitionId);
}
