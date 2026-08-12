import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/head_to_head_record.dart';
import '../domain/profile_repository.dart';
import '../domain/rating_point.dart';
import '../domain/streak.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RatingPoint>> ratingHistory({
    required String seasonId,
    required String playerId,
    int limit = 10,
  }) => guard(() async {
    final rows = await _client
        .from('match_players')
        .select('rating_after, rating_delta, matches!inner(played_at)')
        .eq('player_id', playerId)
        .eq('matches.season_id', seasonId)
        .order('played_at', referencedTable: 'matches', ascending: false)
        .limit(limit);

    return rows
        .map((row) => RatingPoint.fromMap(row))
        .toList(growable: false)
        .reversed
        .toList(growable: false);
  });

  @override
  Future<int> totalMatchesPlayed({required String playerId}) =>
      guard(() async {
        final row = await _client
            .from('player_totals')
            .select('total_played')
            .eq('player_id', playerId)
            .maybeSingle();

        return (row?['total_played'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<Streak> currentStreak({
    required String seasonId,
    required String playerId,
  }) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'player_streak',
      params: {'p_season_id': seasonId, 'p_player_id': playerId},
    );
    if (rows.isEmpty) return const Streak.none();
    return Streak.fromMap(rows.first as Map<String, dynamic>);
  });

  @override
  Future<List<HeadToHeadRecord>> headToHead({
    required String playerId,
    required String opponentId,
  }) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'head_to_head',
      params: {'p_player_id': playerId, 'p_opponent_id': opponentId},
    );
    return rows
        .map((row) => HeadToHeadRecord.fromMap(row as Map<String, dynamic>))
        .toList(growable: false);
  });
}
