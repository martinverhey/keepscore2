import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/realtime.dart';
import '../../../core/error/failure.dart';
import '../domain/player.model.dart';
import '../domain/player_repository.dart';

class SupabasePlayerRepository implements PlayerRepository {
  SupabasePlayerRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Player>> currentPlayers(String competitionId) => guard(() async {
    final rows = await _client
        .from('players')
        .select()
        .eq('competition_id', competitionId)
        .order('display_name');

    return rows.map((row) => Player.fromMap(row)).toList(growable: false);
  });

  @override
  Future<Player> addPlaceholder({
    required String competitionId,
    required String displayName,
  }) => guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'add_dummy_player',
      params: {
        'p_competition_id': competitionId,
        'p_display_name': displayName.trim(),
      },
    );
    return Player.fromMap(row);
  });

  @override
  Future<Player> rename({
    required String playerId,
    required String displayName,
  }) => _update(playerId, {'display_name': displayName.trim()});

  @override
  Future<Player> setActive({
    required String playerId,
    required bool isActive,
  }) => _update(playerId, {'is_active': isActive});

  @override
  Stream<void> watch(String competitionId) => realtimeTicks(
    _client,
    topic: 'players:$competitionId',
    table: 'players',
    column: 'competition_id',
    value: competitionId,
  );

  Future<Player> _update(String playerId, Map<String, Object?> values) =>
      guard(() async {
        final row = await _client
            .from('players')
            .update(values)
            .eq('id', playerId)
            .select()
            .maybeSingle();

        if (row == null) {
          throw const PermissionFailure('This player is not yours to change');
        }
        return Player.fromMap(row);
      });
}
