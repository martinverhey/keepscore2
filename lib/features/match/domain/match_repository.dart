import 'game_type.enum.dart';
import 'match_entry.model.dart';

abstract interface class MatchRepository {
  Future<List<MatchEntry>> feed({
    required String competitionId,
    GameType? gameType,
    int limit = 20,
    int offset = 0,
  });

  Future<MatchEntry?> byId(String matchId);

  Future<List<MatchEntry>> recentForPlayer({
    required String playerId,
    int limit = 3,
  });

  Future<List<MatchEntry>> recentBetweenPlayers({
    required String playerId,
    required String opponentId,
    int limit = 3,
  });

  Future<String> create({
    required String competitionId,
    required List<String> teamA,
    required List<String> teamB,
    required int scoreA,
    required int scoreB,
    DateTime? playedAt,
  });

  Future<void> updateScore({
    required String matchId,
    required int scoreA,
    required int scoreB,
    DateTime? playedAt,
  });

  Future<void> delete(String matchId);

  Stream<void> watch(String competitionId);
}
