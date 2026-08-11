import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/profile_repository.dart';
import '../domain/rating_point.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RatingPoint>> ratingHistory({
    required String seasonId,
    required String playerId,
    int limit = 10,
  }) =>
      guard(() async {
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
}
