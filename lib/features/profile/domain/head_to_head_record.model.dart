import 'package:equatable/equatable.dart';

class HeadToHeadRecord extends Equatable {
  const HeadToHeadRecord({
    required this.wins,
    required this.losses,
    required this.draws,
  });

  factory HeadToHeadRecord.fromMap(Map<String, dynamic> map) =>
      HeadToHeadRecord(
        wins: (map['wins'] as num?)?.toInt() ?? 0,
        losses: (map['losses'] as num?)?.toInt() ?? 0,
        draws: (map['draws'] as num?)?.toInt() ?? 0,
      );

  const HeadToHeadRecord.zero() : wins = 0, losses = 0, draws = 0;

  final int wins;
  final int losses;
  final int draws;

  @override
  List<Object?> get props => [wins, losses, draws];
}
