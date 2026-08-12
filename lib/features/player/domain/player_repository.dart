import 'player.dart';

abstract interface class PlayerRepository {
  Future<List<Player>> roster(String competitionId);

  Future<Player> addPlaceholder({
    required String competitionId,
    required String displayName,
  });

  Future<Player> rename({
    required String playerId,
    required String displayName,
  });

  Future<Player> setActive({required String playerId, required bool isActive});
}
