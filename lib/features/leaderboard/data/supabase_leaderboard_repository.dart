import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/realtime.dart';
import '../../../core/error/failure.dart';
import '../domain/leaderboard.model.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/medals.model.dart';
import '../domain/season.model.dart';
import '../domain/season_leaderboard.model.dart';
import '../domain/season_window.model.dart';

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  SupabaseLeaderboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SeasonWindow> currentSeason(String competitionId, {DateTime? at}) =>
      guard(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'season_window',
          params: {
            'p_competition_id': competitionId,
            if (at != null) 'p_at': at.toUtc().toIso8601String(),
          },
        );
        if (rows.isEmpty) {
          throw const ValidationFailure('You are not in this competition');
        }
        return SeasonWindow.fromMap(rows.first as Map<String, dynamic>);
      });

  @override
  Future<List<Leaderboard>> leaderboards({
    required String competitionId,
    required String? seasonId,
  }) => guard(() async {
    if (seasonId == null) return _leaderboards(competitionId);

    final rows = await _client
        .from('leaderboard')
        .select()
        .eq('competition_id', competitionId)
        .eq('season_id', seasonId)
        .order('rank', ascending: true);

    return rows.map((row) => Leaderboard.fromMap(row)).toList(growable: false);
  });

  Future<List<Leaderboard>> _leaderboards(String competitionId) async {
    final rows = await _client
        .from('players')
        .select(
          'id, display_name, user_id, competitions!inner(starting_rating, owner_id)',
        )
        .eq('competition_id', competitionId)
        .eq('is_active', true)
        .order('display_name', ascending: true);

    return rows
        .map((row) => Leaderboard.forPlayer(row, competitionId: competitionId))
        .toList(growable: false);
  }

  @override
  Stream<void> watchLeaderboards({
    required String competitionId,
    required String? seasonId,
  }) {
    return realtimeTicks(
      _client,
      topic: 'leaderboard:$competitionId:${seasonId ?? 'pending'}',
      table: 'player_ratings',
      column: seasonId == null ? null : 'season_id',
      value: seasonId,
    );
  }

  @override
  Stream<void> watchPlayers({required String competitionId}) {
    return realtimeTicks(
      _client,
      topic: 'leaderboard_players:$competitionId',
      table: 'players',
      column: 'competition_id',
      value: competitionId,
    );
  }

  @override
  Future<List<Season>> finishedSeasons(String competitionId) => guard(() async {
    final rows = await _client
        .from('finished_seasons')
        .select('season_id, starts_at, ends_at')
        .eq('competition_id', competitionId)
        .order('starts_at', ascending: false);

    return rows
        .map(
          (row) => Season.fromMap({
            'id': row['season_id'],
            'starts_at': row['starts_at'],
            'ends_at': row['ends_at'],
          }),
        )
        .toList(growable: false);
  });

  @override
  Future<List<SeasonLeaderboard>> history({
    required String competitionId,
    String? seasonId,
    String? playerId,
  }) => guard(() async {
    var query = _client
        .from('season_history')
        .select()
        .eq('competition_id', competitionId);
    if (seasonId != null) query = query.eq('season_id', seasonId);
    if (playerId != null) query = query.eq('player_id', playerId);

    final rows = await query
        .order('starts_at', ascending: false)
        .order('rank', ascending: true);

    return rows
        .map((row) => SeasonLeaderboard.fromMap(row))
        .toList(growable: false);
  });

  @override
  Future<List<Medals>> medals(String competitionId) => guard(() async {
    final rows = await _client
        .from('player_medals')
        .select()
        .eq('competition_id', competitionId);

    return rows.map((row) => Medals.fromMap(row)).toList(growable: false);
  });
}
