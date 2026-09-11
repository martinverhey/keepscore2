import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/realtime.dart';
import '../../../core/error/failure.dart';
import '../domain/bracket.model.dart';
import '../domain/tournament.model.dart';
import '../domain/tournament_repository.dart';

class SupabaseTournamentRepository implements TournamentRepository {
  SupabaseTournamentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Tournament?> latest(String competitionId) => guard(() async {
    final row = await _client
        .from('tournaments')
        .select()
        .eq('competition_id', competitionId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return row == null ? null : Tournament.fromMap(row);
  });

  @override
  Future<Bracket> bracket(String tournamentId) => guard(() async {
    final rows = await _client
        .from('tournament_bracket')
        .select()
        .eq('tournament_id', tournamentId)
        .order('round')
        .order('slot');

    return Bracket.fromMatches(
      rows.map((row) => TournamentMatch.fromMap(row)).toList(growable: false),
    );
  });

  @override
  Future<String> start({
    required String competitionId,
    required List<String> playerIds,
  }) => guard(() async {
    return await _client.rpc<String>(
      'start_tournament',
      params: {'p_competition_id': competitionId, 'p_player_ids': playerIds},
    );
  });

  @override
  Future<void> setResult({
    required String tournamentMatchId,
    required int scoreA,
    required int scoreB,
  }) => guard(() async {
    await _client.rpc<void>(
      'set_tournament_result',
      params: {
        'p_tournament_match_id': tournamentMatchId,
        'p_score_a': scoreA,
        'p_score_b': scoreB,
      },
    );
  });

  @override
  Future<void> cancel(String tournamentId) => guard(() async {
    await _client.rpc<void>(
      'cancel_tournament',
      params: {'p_tournament_id': tournamentId},
    );
  });

  @override
  Stream<void> watchTournaments(String competitionId) => realtimeTicks(
    _client,
    topic: 'tournaments:$competitionId',
    table: 'tournaments',
    column: 'competition_id',
    value: competitionId,
  );

  @override
  Stream<void> watchBracket(String tournamentId) => realtimeTicks(
    _client,
    topic: 'tournament_matches:$tournamentId',
    table: 'tournament_matches',
    column: 'tournament_id',
    value: tournamentId,
  );
}
