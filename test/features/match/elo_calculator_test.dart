import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/elo_calculator.dart';

void main() {
  const settings = EloSettings();
  const noMov = EloSettings(movEnabled: false);

  double d(double a, double b, int sa, int sb, [EloSettings s = settings]) =>
      EloCalculator.delta(
        ratingA: a,
        ratingB: b,
        scoreA: sa,
        scoreB: sb,
        settings: s,
      );

  group('elo_delta parity fixtures', () {
    test('even players, one-point win is half the pot plus one', () {
      expect(d(1000, 1000, 10, 9), 31);
      expect(d(1000, 1000, 9, 10), -31);
    });

    test('a draw between equals moves nothing', () {
      expect(d(1000, 1000, 5, 5), 0);
    });

    test('the extra points stop at the cap', () {
      expect(d(1000, 1000, 11, 1), 35);
      expect(d(1000, 1000, 21, 1), 35);
    });

    test('a shutout doubles the extra points', () {
      expect(d(1000, 1000, 10, 0), 40);
      expect(d(1000, 1000, 0, 10), -40);
    });

    test('a shutout is an ordinary margin with the bonus off', () {
      expect(d(1000, 1000, 10, 0, const EloSettings(shutoutBonus: false)), 35);
    });

    test('the shutout multiplier scales the extra points', () {
      expect(
        d(1000, 1000, 10, 0, const EloSettings(shutoutMultiplier: 1.5)),
        38,
      );
    });

    test('margin is ignored when MOV is disabled', () {
      expect(d(1000, 1000, 10, 0, noMov), 30);
      expect(d(1000, 1000, 10, 9, noMov), 30);
    });

    test('the favourite gains the pot times the loser\'s chance', () {
      expect(d(1200, 1000, 11, 9), 15);
    });

    test('the underdog gains far more', () {
      expect(d(1000, 1200, 11, 9), 47);
    });

    test('a win is always worth at least one point', () {
      expect(d(2000, 1000, 11, 9), 1);
      expect(d(1000, 2000, 9, 11), -1);
    });

    test('is antisymmetric, so ratings stay zero-sum', () {
      expect(d(1350, 990, 21, 13), -d(990, 1350, 13, 21));
      expect(d(1000, 1000, 7, 3), -d(1000, 1000, 3, 7));
      expect(d(1100, 1000, 5, 5), -d(1000, 1100, 5, 5));
    });

    test('always returns whole points', () {
      for (final (a, b, sa, sb) in [
        (1013.0, 987.0, 11, 7),
        (1240.0, 1180.0, 3, 11),
        (990.0, 1060.0, 6, 6),
      ]) {
        final delta = d(a, b, sa, sb);
        expect(delta, delta.roundToDouble());
      }
    });
  });

  group('teamRating', () {
    test('is the mean of its members', () {
      expect(EloCalculator.teamRating([1000, 1200]), 1100);
      expect(EloCalculator.teamRating([980, 1010, 1040, 1050]), 1020);
    });

    test('rejects an empty team', () {
      expect(() => EloCalculator.teamRating([]), throwsArgumentError);
    });
  });
}
