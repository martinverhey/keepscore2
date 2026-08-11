import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/realtime.dart';
import '../../../core/error/failure.dart';
import '../domain/leaderboard.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/season.dart';
import '../domain/season_window.dart';

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
  Future<List<Season>> seasons(String competitionId) => guard(() async {
    final rows = await _client
        .from('seasons')
        .select()
        .eq('competition_id', competitionId)
        .order('starts_at', ascending: false);

    return rows.map((row) => Season.fromMap(row)).toList(growable: false);
  });

  @override
  Future<List<Leaderboard>> standings({
    required String competitionId,
    required String? seasonId,
  }) => guard(() async {
    if (seasonId == null) return const [];

    final rows = await _client
        .from('leaderboard')
        .select()
        .eq('competition_id', competitionId)
        .eq('season_id', seasonId)
        .order('rank', ascending: true);

    return rows.map((row) => Leaderboard.fromMap(row)).toList(growable: false);
  });

  @override
  Stream<void> watchStandings({
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
}
