import 'player.model.dart';

abstract interface class PlayerRepository {
  Future<List<Player>> currentPlayers(String competitionId);

  Future<Player> addPlaceholder({
    required String competitionId,
    required String displayName,
  });

  Future<Player> rename({
    required String playerId,
    required String displayName,
  });

  Future<Player> setActive({required String playerId, required bool isActive});

  Stream<void> watch(String competitionId);
}
