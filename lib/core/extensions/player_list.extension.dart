import '../../features/player/domain/player.model.dart';

extension PlayerListActive on List<Player> {
  List<Player> get active =>
      where((player) => player.isActive).toList(growable: false);
}

extension PlayerListDisplayName on List<Player> {
  String? displayNameFor(String? playerId) {
    for (final player in this) {
      if (player.id == playerId) return player.displayName;
    }
    return null;
  }
}
