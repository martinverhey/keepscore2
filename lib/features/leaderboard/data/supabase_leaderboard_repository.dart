import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/realtime.dart';
import '../../../core/error/failure.dart';
import '../../match/domain/game_type.enum.dart';
import '../domain/leaderboard.model.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/medals.model.dart';
import '../domain/season_standing.model.dart';
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
    GameType? gameType,
  }) => guard(() async {
    if (seasonId == null) {
      return gameType == null
          ? _rosterLeaderboards(competitionId)
          : <Leaderboard>[];
    }

    var query = _client
        .from(gameType == null ? 'leaderboard' : 'game_type_leaderboard')
        .select()
        .eq('competition_id', competitionId)
        .eq('season_id', seasonId);
    if (gameType != null) query = query.eq('game_type', gameType.wireValue);

    final rows = await query.order('rank', ascending: true);

    return rows.map((row) => Leaderboard.fromMap(row)).toList(growable: false);
  });

  Future<List<Leaderboard>> _rosterLeaderboards(String competitionId) async {
    final rows = await _client
        .from('players')
        .select(
          'id, display_name, user_id, competitions!inner(starting_rating, owner_id)',
        )
        .eq('competition_id', competitionId)
        .eq('is_active', true)
        .order('display_name', ascending: true);

    return rows
        .map(
          (row) =>
              Leaderboard.forRosterPlayer(row, competitionId: competitionId),
        )
        .toList(growable: false);
  }

  @override
  Stream<void> watchLeaderboards({
    required String competitionId,
    required String? seasonId,
    GameType? gameType,
  }) {
    return realtimeTicks(
      _client,
      topic:
          'leaderboard:$competitionId:${seasonId ?? 'pending'}:${gameType?.wireValue ?? 'combined'}',
      table: gameType == null ? 'player_ratings' : 'player_game_type_ratings',
      column: seasonId == null ? null : 'season_id',
      value: seasonId,
    );
  }

  @override
  Future<List<SeasonStanding>> seasonHistory({
    required String competitionId,
    String? playerId,
    GameType? gameType,
  }) => guard(() async {
    var query = _client
        .from(gameType == null ? 'season_history' : 'game_type_season_history')
        .select()
        .eq('competition_id', competitionId);
    if (playerId != null) query = query.eq('player_id', playerId);
    if (gameType != null) query = query.eq('game_type', gameType.wireValue);

    final rows = await query
        .order('starts_at', ascending: false)
        .order('rank', ascending: true);

    return rows
        .map((row) => SeasonStanding.fromMap(row))
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
