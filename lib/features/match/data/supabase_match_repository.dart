import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/realtime.dart';
import '../../../core/error/failure.dart';
import '../domain/game_type.enum.dart';
import '../domain/match_entry.model.dart';
import '../domain/match_repository.dart';

class SupabaseMatchRepository implements MatchRepository {
  SupabaseMatchRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MatchEntry>> feed({
    required String competitionId,
    GameType? gameType,
    int limit = 20,
    int offset = 0,
  }) => guard(() async {
    var query = _client
        .from('match_feed')
        .select()
        .eq('competition_id', competitionId);
    if (gameType != null) {
      query = query.eq('game_type', gameType.wireValue);
    }

    final rows = await query
        .order('played_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    return rows.map((row) => MatchEntry.fromMap(row)).toList(growable: false);
  });

  @override
  Future<Set<GameType>> seasonGameTypes(String competitionId) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'season_game_types',
      params: {'p_competition_id': competitionId},
    );

    return {
      for (final row in rows)
        GameType.fromWire((row as Map<String, dynamic>)['game_type'] as String),
    };
  });

  @override
  Future<MatchEntry?> byId(String matchId) => guard(() async {
    final row = await _client
        .from('match_feed')
        .select()
        .eq('id', matchId)
        .maybeSingle();

    return row == null ? null : MatchEntry.fromMap(row);
  });

  @override
  Future<List<MatchEntry>> recentForPlayer({
    required String playerId,
    int limit = 3,
  }) => guard(() async {
    final links = await _client
        .from('match_players')
        .select('match_id, matches!inner(played_at)')
        .eq('player_id', playerId)
        .order('played_at', referencedTable: 'matches', ascending: false)
        .limit(limit);

    if (links.isEmpty) return const <MatchEntry>[];

    final ids = links.map((row) => row['match_id'] as String).toList();
    final rows = await _client
        .from('match_feed')
        .select()
        .inFilter('id', ids)
        .order('played_at', ascending: false)
        .order('id', ascending: false);

    return rows.map((row) => MatchEntry.fromMap(row)).toList(growable: false);
  });

  @override
  Future<List<MatchEntry>> recentBetweenPlayers({
    required String playerId,
    required String opponentId,
    int limit = 3,
  }) => guard(() async {
    final links = await _client.rpc<List<dynamic>>(
      'head_to_head_match_ids',
      params: {
        'p_player_id': playerId,
        'p_opponent_id': opponentId,
        'p_limit': limit,
      },
    );
    if (links.isEmpty) return const <MatchEntry>[];

    final ids = links
        .map((row) => (row as Map<String, dynamic>)['match_id'] as String)
        .toList();
    final rows = await _client
        .from('match_feed')
        .select()
        .inFilter('id', ids)
        .order('played_at', ascending: false)
        .order('id', ascending: false);

    return rows.map((row) => MatchEntry.fromMap(row)).toList(growable: false);
  });

  @override
  Future<String> create({
    required String competitionId,
    required List<String> teamA,
    required List<String> teamB,
    required int scoreA,
    required int scoreB,
    DateTime? playedAt,
  }) => guard(() async {
    return await _client.rpc<String>(
      'create_match',
      params: {
        'p_competition_id': competitionId,
        'p_team_a': teamA,
        'p_team_b': teamB,
        'p_score_a': scoreA,
        'p_score_b': scoreB,
        if (playedAt != null) 'p_played_at': playedAt.toUtc().toIso8601String(),
      },
    );
  });

  @override
  Future<void> updateScore({
    required String matchId,
    required int scoreA,
    required int scoreB,
    DateTime? playedAt,
  }) => guard(() async {
    await _client.rpc<void>(
      'update_match_score',
      params: {
        'p_match_id': matchId,
        'p_score_a': scoreA,
        'p_score_b': scoreB,
        if (playedAt != null) 'p_played_at': playedAt.toUtc().toIso8601String(),
      },
    );
  });

  @override
  Future<void> delete(String matchId) => guard(() async {
    await _client.rpc<void>('delete_match', params: {'p_match_id': matchId});
  });

  @override
  Stream<void> watch(String competitionId) => realtimeTicks(
    _client,
    topic: 'matches:$competitionId',
    table: 'matches',
    column: 'competition_id',
    value: competitionId,
  );
}
