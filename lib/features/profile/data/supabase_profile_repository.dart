import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../match/domain/game_type.enum.dart';
import '../domain/best_streaks.model.dart';
import '../domain/head_to_head_record.model.dart';
import '../domain/profile_repository.dart';
import '../domain/rating_point.model.dart';
import '../domain/recent_played.model.dart';
import '../domain/streak.model.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RatingPoint>> ratingHistory({
    required String seasonId,
    required String playerId,
    GameType? gameType,
    int limit = 10,
  }) => guard(() async {
    final columns = gameType == null
        ? 'rating_after, rating_delta'
        : 'rating_after:type_rating_after, rating_delta:type_rating_delta';

    var query = _client
        .from('match_players')
        .select('$columns, matches!inner(played_at)')
        .eq('player_id', playerId)
        .eq('matches.season_id', seasonId);
    if (gameType != null) {
      query = query.eq('matches.game_type', gameType.wireValue);
    }

    final rows = await query
        .order('played_at', referencedTable: 'matches', ascending: false)
        .limit(limit);

    return rows
        .map((row) => RatingPoint.fromMap(row))
        .toList(growable: false)
        .reversed
        .toList(growable: false);
  });

  @override
  Future<int> totalMatchesPlayed({
    required String playerId,
    GameType? gameType,
  }) => guard(() async {
    final table = gameType == null
        ? 'player_totals'
        : 'player_game_type_totals';
    var query = _client
        .from(table)
        .select('total_played')
        .eq('player_id', playerId);
    if (gameType != null) query = query.eq('game_type', gameType.wireValue);

    final row = await query.maybeSingle();
    return (row?['total_played'] as num?)?.toInt() ?? 0;
  });

  @override
  Future<Streak> currentStreak({
    required String seasonId,
    required String playerId,
    GameType? gameType,
  }) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'player_streak',
      params: {
        'p_season_id': seasonId,
        'p_player_id': playerId,
        if (gameType != null) 'p_game_type': gameType.wireValue,
      },
    );
    if (rows.isEmpty) return const Streak.none();
    return Streak.fromMap(rows.first as Map<String, dynamic>);
  });

  @override
  Future<BestStreaks> bestStreaks({
    required String playerId,
    GameType? gameType,
  }) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'player_best_streaks',
      params: {
        'p_player_id': playerId,
        if (gameType != null) 'p_game_type': gameType.wireValue,
      },
    );
    if (rows.isEmpty) return const BestStreaks.zero();
    return BestStreaks.fromMap(rows.first as Map<String, dynamic>);
  });

  @override
  Future<RecentPlayed> recentPlayed({
    required String seasonId,
    required String playerId,
    GameType? gameType,
  }) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'player_recent_played',
      params: {
        'p_season_id': seasonId,
        'p_player_id': playerId,
        if (gameType != null) 'p_game_type': gameType.wireValue,
      },
    );
    if (rows.isEmpty) return const RecentPlayed.zero();
    return RecentPlayed.fromMap(rows.first as Map<String, dynamic>);
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

  @override
  Future<double> bestRating({required String playerId, GameType? gameType}) =>
      guard(() async {
        final result = await _client.rpc<num>(
          'player_best_rating',
          params: {
            'p_player_id': playerId,
            if (gameType != null) 'p_game_type': gameType.wireValue,
          },
        );
        return result.toDouble();
      });
}
