import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/extensions/string.extension.dart';
import '../../player/domain/player.model.dart';
import '../domain/competition.model.dart';
import '../domain/competition_repository.dart';
import '../domain/join_preview.model.dart';

class SupabaseCompetitionRepository implements CompetitionRepository {
  SupabaseCompetitionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CompetitionOverview>> myCompetitions() => guard(() async {
    final rows = await _client
        .from('competition_overview')
        .select()
        .order('last_played_at', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false);

    return rows
        .map((row) => CompetitionOverview.fromMap(row))
        .toList(growable: false);
  });

  @override
  Future<CompetitionOverview?> overview(String competitionId) =>
      guard(() async {
        final row = await _client
            .from('competition_overview')
            .select()
            .eq('id', competitionId)
            .maybeSingle();

        return row == null ? null : CompetitionOverview.fromMap(row);
      });

  @override
  Future<Competition> create({
    required String name,
    required SeasonLength seasonLength,
    String? displayName,
  }) => guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_competition',
      params: {
        'p_name': name.trim(),
        'p_season_length': seasonLength.wireName,
        if (displayName != null && displayName.trim().isNotEmpty)
          'p_display_name': displayName.trim(),
      },
    );
    return Competition.fromMap(row);
  });

  @override
  Future<JoinPreview> preview(String joinCode) => guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'preview_competition',
      params: {'p_join_code': joinCode.normalizedJoinCode},
    );
    if (rows.isEmpty) {
      throw const ValidationFailure('No competition with that code');
    }
    return JoinPreview.fromMap(rows.first as Map<String, dynamic>);
  });

  @override
  Future<Player> join({
    required String joinCode,
    String? displayName,
    String? claimPlayerId,
  }) => guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'join_competition',
      params: {
        'p_join_code': joinCode.normalizedJoinCode,
        if (displayName != null && displayName.trim().isNotEmpty)
          'p_display_name': displayName.trim(),
        'p_claim_player_id': ?claimPlayerId,
      },
    );
    return Player.fromMap(row);
  });

  @override
  Future<Competition> updateSettings({
    required String competitionId,
    required String name,
    required SeasonLength seasonLength,
    required int kFactor,
    required bool movEnabled,
    required double movCap,
    required bool allowDraws,
  }) => guard(() async {
    final row = await _client
        .from('competitions')
        .update({
          'name': name.trim(),
          'season_length': seasonLength.wireName,
          'k_factor': kFactor,
          'mov_enabled': movEnabled,
          'mov_cap': movCap,
          'allow_draws': allowDraws,
        })
        .eq('id', competitionId)
        .select()
        .maybeSingle();

    if (row == null) {
      throw const PermissionFailure(
        'Only the competition owner can change these settings',
      );
    }
    return Competition.fromMap(row);
  });

  @override
  Future<void> leave(String competitionId) => guard(() async {
    await _client.rpc(
      'leave_competition',
      params: {'p_competition_id': competitionId},
    );
  });

  @override
  Future<void> delete(String competitionId) => guard(() async {
    final row = await _client
        .from('competitions')
        .delete()
        .eq('id', competitionId)
        .select()
        .maybeSingle();

    if (row == null) {
      throw const PermissionFailure(
        'Only the competition owner can delete this competition',
      );
    }
  });
}
