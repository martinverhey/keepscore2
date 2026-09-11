import 'package:equatable/equatable.dart';

import 'tournament_entrant.model.dart';

export 'tournament_entrant.model.dart';

class TournamentMatch extends Equatable {
  const TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.slot,
    this.playerA,
    this.playerB,
    this.scoreA,
    this.scoreB,
    this.winnerPlayerId,
    this.playedAt,
  });

  factory TournamentMatch.fromMap(Map<String, dynamic> map) => TournamentMatch(
    id: map['id'] as String,
    tournamentId: map['tournament_id'] as String,
    round: (map['round'] as num).toInt(),
    slot: (map['slot'] as num).toInt(),
    playerA: TournamentEntrant.fromMap(
      map,
      idKey: 'player_a_id',
      nameKey: 'player_a_name',
    ),
    playerB: TournamentEntrant.fromMap(
      map,
      idKey: 'player_b_id',
      nameKey: 'player_b_name',
    ),
    scoreA: (map['score_a'] as num?)?.toInt(),
    scoreB: (map['score_b'] as num?)?.toInt(),
    winnerPlayerId: map['winner_player_id'] as String?,
    playedAt: switch (map['played_at']) {
      final String value => DateTime.parse(value).toLocal(),
      _ => null,
    },
  );

  final String id;
  final String tournamentId;
  final int round;
  final int slot;
  final TournamentEntrant? playerA;
  final TournamentEntrant? playerB;
  final int? scoreA;
  final int? scoreB;
  final String? winnerPlayerId;
  final DateTime? playedAt;

  bool get isPlayed => playedAt != null;

  bool get isBye => winnerPlayerId != null && playedAt == null;

  bool get isPlayable => playerA != null && playerB != null;

  bool get isWaiting => playerA == null || playerB == null;

  TournamentEntrant? get winner => switch (winnerPlayerId) {
    final String id when playerA?.playerId == id => playerA,
    final String id when playerB?.playerId == id => playerB,
    _ => null,
  };

  bool isWinner(TournamentEntrant entrant) =>
      winnerPlayerId != null && winnerPlayerId == entrant.playerId;

  @override
  List<Object?> get props => [
    id,
    tournamentId,
    round,
    slot,
    playerA,
    playerB,
    scoreA,
    scoreB,
    winnerPlayerId,
    playedAt,
  ];
}
