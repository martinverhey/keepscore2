import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/head_to_head_record.model.dart';
import '../domain/profile_repository.dart';
import '../domain/profile_stats.model.dart';
import '../domain/rating_point.model.dart';

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
  Future<ProfileStats> profileStats({
    required String playerId,
    String? seasonId,
  }) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'player_profile_stats',
      params: {'p_player_id': playerId, 'p_season_id': seasonId},
    );
    if (rows.isEmpty) return ProfileStats.fromMap(const {});
    return ProfileStats.fromMap(rows.first as Map<String, dynamic>);
  });

  @override
  Future<HeadToHeadRecord> headToHead({
    required String playerId,
    required String opponentId,
  }) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'head_to_head',
      params: {'p_player_id': playerId, 'p_opponent_id': opponentId},
    );
    if (rows.isEmpty) return const HeadToHeadRecord.zero();
    return HeadToHeadRecord.fromMap(rows.first as Map<String, dynamic>);
  });
}
