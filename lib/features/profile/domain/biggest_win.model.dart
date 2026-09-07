import 'package:equatable/equatable.dart';

class BiggestWin extends Equatable {
  const BiggestWin({required this.score, required this.opponentScore});

  final int score;
  final int opponentScore;

  @override
  List<Object?> get props => [score, opponentScore];
}
