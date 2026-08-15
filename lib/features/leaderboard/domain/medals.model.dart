import 'package:equatable/equatable.dart';

class Medals extends Equatable {
  const Medals({
    required this.playerId,
    required this.gold,
    required this.silver,
    required this.bronze,
  });

  factory Medals.fromMap(Map<String, dynamic> map) => Medals(
    playerId: map['player_id'] as String,
    gold: (map['gold'] as num?)?.toInt() ?? 0,
    silver: (map['silver'] as num?)?.toInt() ?? 0,
    bronze: (map['bronze'] as num?)?.toInt() ?? 0,
  );

  final String playerId;
  final int gold;
  final int silver;
  final int bronze;

  bool get hasAny => gold > 0 || silver > 0 || bronze > 0;

  @override
  List<Object?> get props => [playerId, gold, silver, bronze];
}
