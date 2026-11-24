import 'dart:math' as math;

import 'elo_settings.model.dart';

export 'elo_settings.model.dart';

abstract final class EloCalculator {
  static const int _minimumWin = 1;

  static double teamRating(Iterable<double> ratings) {
    final values = ratings.toList(growable: false);
    if (values.isEmpty) {
      throw ArgumentError('A team needs at least one player');
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double winChance({required double ratingA, required double ratingB}) =>
      1.0 / (1.0 + math.pow(10.0, (ratingB - ratingA) / 400.0));

  static double delta({
    required double ratingA,
    required double ratingB,
    required int scoreA,
    required int scoreB,
    required EloSettings settings,
  }) {
    final expectedA = winChance(ratingA: ratingA, ratingB: ratingB);

    if (scoreA == scoreB) {
      return (settings.kFactor * (0.5 - expectedA)).round().toDouble();
    }

    final aWon = scoreA > scoreB;
    final winnerExpected = aWon ? expectedA : 1.0 - expectedA;
    final pot = settings.kFactor + _extraPoints(scoreA, scoreB, settings);
    final points = math.max(
      _minimumWin,
      (pot * (1.0 - winnerExpected)).round(),
    );

    return (aWon ? points : -points).toDouble();
  }

  static double _extraPoints(int scoreA, int scoreB, EloSettings settings) {
    if (!settings.movEnabled) return 0;
    final margin = math.min(
      (scoreA - scoreB).abs().toDouble(),
      settings.movCap,
    );
    final multiplies = settings.shutoutBonus && math.min(scoreA, scoreB) == 0;
    return multiplies ? margin * settings.shutoutMultiplier : margin;
  }
}
