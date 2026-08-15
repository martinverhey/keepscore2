import 'dart:math' as math;

import 'elo_preview.model.dart';
import 'elo_settings.model.dart';

export 'elo_preview.model.dart';
export 'elo_settings.model.dart';

abstract final class EloCalculator {
  static double teamRating(Iterable<double> ratings) {
    final values = ratings.toList(growable: false);
    if (values.isEmpty) {
      throw ArgumentError('A team needs at least one player');
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double delta({
    required double ratingA,
    required double ratingB,
    required int scoreA,
    required int scoreB,
    required EloSettings settings,
  }) {
    final expectedA = 1.0 / (1.0 + math.pow(10.0, (ratingB - ratingA) / 400.0));

    final actualA = scoreA > scoreB
        ? 1.0
        : scoreA < scoreB
        ? 0.0
        : 0.5;

    final margin = (scoreA - scoreB).abs();
    var mov = 1.0;

    if (settings.movEnabled && margin > 0) {
      final winnerEdge = math.max(
        0.0,
        actualA == 1.0 ? ratingA - ratingB : ratingB - ratingA,
      );
      mov =
          (math.log(margin + 1) / math.ln2) *
          (2.2 / (0.001 * winnerEdge + 2.2));
      mov = math.min(settings.movCap, math.max(1.0, mov));
    }

    return _round2(settings.kFactor * mov * (actualA - expectedA));
  }

  static EloPreview preview({
    required List<double> teamA,
    required List<double> teamB,
    required int scoreA,
    required int scoreB,
    required EloSettings settings,
  }) {
    final ratingA = teamRating(teamA);
    final ratingB = teamRating(teamB);
    return EloPreview(
      teamARating: ratingA,
      teamBRating: ratingB,
      deltaA: delta(
        ratingA: ratingA,
        ratingB: ratingB,
        scoreA: scoreA,
        scoreB: scoreB,
        settings: settings,
      ),
    );
  }

  static double _round2(double value) => (value * 100).round() / 100;
}
