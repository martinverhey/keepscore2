import 'package:equatable/equatable.dart';

import 'biggest_win.model.dart';

export 'biggest_win.model.dart';

class HeadToHeadRecord extends Equatable {
  const HeadToHeadRecord({
    required this.wins,
    required this.losses,
    required this.draws,
    this.biggestWin,
    this.biggestShutout,
    this.shutoutWins = 0,
  });

  factory HeadToHeadRecord.fromMap(Map<String, dynamic> map) =>
      HeadToHeadRecord(
        wins: (map['wins'] as num?)?.toInt() ?? 0,
        losses: (map['losses'] as num?)?.toInt() ?? 0,
        draws: (map['draws'] as num?)?.toInt() ?? 0,
        biggestWin: _biggestWin(map),
        biggestShutout: _biggestShutout(map),
        shutoutWins: (map['shutout_wins'] as num?)?.toInt() ?? 0,
      );

  const HeadToHeadRecord.zero()
    : wins = 0,
      losses = 0,
      draws = 0,
      biggestWin = null,
      biggestShutout = null,
      shutoutWins = 0;

  final int wins;
  final int losses;
  final int draws;
  final BiggestWin? biggestWin;
  final BiggestWin? biggestShutout;
  final int shutoutWins;

  @override
  List<Object?> get props => [
    wins,
    losses,
    draws,
    biggestWin,
    biggestShutout,
    shutoutWins,
  ];
}

BiggestWin? _biggestWin(Map<String, dynamic> map) {
  final score = (map['biggest_win_score'] as num?)?.toInt();
  final opponentScore = (map['biggest_win_opponent_score'] as num?)?.toInt();
  if (score == null || opponentScore == null) return null;

  return BiggestWin(score: score, opponentScore: opponentScore);
}

BiggestWin? _biggestShutout(Map<String, dynamic> map) {
  final score = (map['biggest_shutout_score'] as num?)?.toInt();
  if (score == null) return null;

  return BiggestWin(score: score, opponentScore: 0);
}
