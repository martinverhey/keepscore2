import 'package:equatable/equatable.dart';

class PlannedMatch extends Equatable {
  const PlannedMatch({required this.playerAId, required this.playerBId});

  factory PlannedMatch.fromMap(Map<String, dynamic> map) => PlannedMatch(
    playerAId: map['player_a_id'] as String,
    playerBId: map['player_b_id'] as String,
  );

  final String playerAId;
  final String playerBId;

  String get pairKey => ([playerAId, playerBId]..sort()).join('|');

  Map<String, dynamic> toMap() => {
    'player_a_id': playerAId,
    'player_b_id': playerBId,
  };

  @override
  List<Object?> get props => [playerAId, playerBId];
}
