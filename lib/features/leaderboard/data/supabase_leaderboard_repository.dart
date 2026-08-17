import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/realtime.dart';
import '../../../core/error/failure.dart';
import '../../match/domain/game_type.enum.dart';
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
    GameType? gameType,
  }) => guard(() async {
    if (seasonId == null) {
      return gameType == null ? _leaderboards(competitionId) : <Leaderboard>[];
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
    GameType? gameType,
  }) => guard(() async {
    var query = _client
        .from(gameType == null ? 'season_history' : 'game_type_season_history')
        .select()
        .eq('competition_id', competitionId);
    if (seasonId != null) query = query.eq('season_id', seasonId);
    if (playerId != null) query = query.eq('player_id', playerId);
    if (gameType != null) query = query.eq('game_type', gameType.wireValue);

    final rows = await query
        .order('starts_at', ascending: false)
        .order('rank', ascending: true);

    return rows
        .map((row) => SeasonLeaderboard.fromMap(row))
        .toList(growable: false);
  });

  @override
  Future<List<Medals>> medals(String competitionId, {GameType? gameType}) =>
      guard(() async {
        var query = _client
            .from(
              gameType == null ? 'player_medals' : 'game_type_player_medals',
            )
            .select()
            .eq('competition_id', competitionId);
        if (gameType != null) {
          query = query.eq('game_type', gameType.wireValue);
        }

        final rows = await query;
        return rows.map((row) => Medals.fromMap(row)).toList(growable: false);
      });
}
