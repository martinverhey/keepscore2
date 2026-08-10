import '../../player/domain/player.dart';
import 'competition.dart';
import 'join_preview.dart';

abstract interface class CompetitionRepository {
  Future<List<CompetitionOverview>> myCompetitions();

  Future<CompetitionOverview?> overview(String competitionId);

  Future<Competition> create({
    required String name,
    required SeasonLength seasonLength,
    String? displayName,
  });

  Future<Competition> updateSettings({
    required String competitionId,
    required String name,
    required SeasonLength seasonLength,
    required int kFactor,
    required bool movEnabled,
    required double movCap,
    required bool allowDraws,
  });

  Future<JoinPreview> preview(String joinCode);

  Future<Player> join({
    required String joinCode,
    String? displayName,
    String? claimPlayerId,
  });
}
