import 'package:equatable/equatable.dart';

class BestStreaks extends Equatable {
  const BestStreaks({required this.win, required this.loss});

  const BestStreaks.zero() : win = 0, loss = 0;

  factory BestStreaks.fromMap(Map<String, dynamic> map) => BestStreaks(
    win: (map['best_win_streak'] as num?)?.toInt() ?? 0,
    loss: (map['best_loss_streak'] as num?)?.toInt() ?? 0,
  );

  final int win;
  final int loss;

  @override
  List<Object?> get props => [win, loss];
}
