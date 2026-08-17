import '../../features/player/domain/player.model.dart';

extension PlayerListActive on List<Player> {
  List<Player> get active =>
      where((player) => player.isActive).toList(growable: false);
}
