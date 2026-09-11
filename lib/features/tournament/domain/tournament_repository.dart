import 'bracket.model.dart';
import 'tournament.model.dart';

abstract interface class TournamentRepository {
  Future<Tournament?> latest(String competitionId);

  Future<Bracket> bracket(String tournamentId);

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
