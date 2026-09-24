import 'bracket.model.dart';
import 'tournament.model.dart';

abstract interface class TournamentRepository {
  Future<List<Tournament>> all(String competitionId);

  Future<Map<String, Bracket>> brackets(String competitionId);

  Future<String> start({
    required String competitionId,
    required List<String> playerIds,
  });

  Future<void> setResult({
    required String tournamentMatchId,
    required int scoreA,
    required int scoreB,
  });

  Future<void> cancel(String tournamentId);

  Stream<void> watchTournaments(String competitionId);

  Stream<void> watchBracket(String tournamentId);
}
