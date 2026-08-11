import 'match_entry.dart';

abstract interface class MatchRepository {
  Future<List<MatchEntry>> feed({
    required String competitionId,
    int limit = 20,
    int offset = 0,
  });

  Future<MatchEntry?> byId(String matchId);

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
