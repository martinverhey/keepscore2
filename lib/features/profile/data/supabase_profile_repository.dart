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
        .from('matches')
        .select('played_at, match_players!inner(rating_after, rating_delta)')
        .eq('season_id', seasonId)
        .eq('match_players.player_id', playerId)
        .order('played_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return [for (final row in rows.reversed) RatingPoint.fromMap(row)];
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
