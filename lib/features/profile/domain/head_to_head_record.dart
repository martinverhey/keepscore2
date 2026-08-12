import 'package:equatable/equatable.dart';

import '../../match/domain/game_type.dart';

class HeadToHeadRecord extends Equatable {
  const HeadToHeadRecord({
    required this.gameType,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  factory HeadToHeadRecord.fromMap(Map<String, dynamic> map) =>
      HeadToHeadRecord(
        gameType: GameType.fromWire(map['game_type'] as String),
        wins: (map['wins'] as num?)?.toInt() ?? 0,
        losses: (map['losses'] as num?)?.toInt() ?? 0,
        draws: (map['draws'] as num?)?.toInt() ?? 0,
      );

  final GameType gameType;
  final int wins;
  final int losses;
  final int draws;

  @override
  List<Object?> get props => [gameType, wins, losses, draws];
}
