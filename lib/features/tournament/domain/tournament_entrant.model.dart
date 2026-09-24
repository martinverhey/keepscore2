import 'package:equatable/equatable.dart';

class TournamentEntrant extends Equatable {
  const TournamentEntrant({required this.playerId, required this.displayName});

  static TournamentEntrant? fromMap(
    Map<String, dynamic> map, {
    required String idKey,
    required String nameKey,
  }) {
    final playerId = map[idKey] as String?;
    if (playerId == null) return null;

    return TournamentEntrant(
      playerId: playerId,
      displayName: map[nameKey] as String? ?? '',
    );
  }

  final String playerId;
  final String displayName;

  @override
  List<Object?> get props => [playerId, displayName];
}
