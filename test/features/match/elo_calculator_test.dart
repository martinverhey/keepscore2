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
    test('even players, one-point win is plain Elo', () {
      expect(d(1000, 1000, 10, 9), 16.00);
      expect(d(1000, 1000, 9, 10), -16.00);
    });

    test('a draw between equals moves nothing', () {
      expect(d(1000, 1000, 5, 5), 0.00);
    });

    test('a blowout clamps at the cap', () {
      expect(d(1000, 1000, 10, 0), 40.00);
    });

    test('margin is ignored when MOV is disabled', () {
      expect(d(1000, 1000, 10, 0, noMov), 16.00);
      expect(d(1000, 1000, 10, 9, noMov), 16.00);
    });

    test('the favourite gains less than an even player would', () {
      expect(d(1200, 1000, 11, 9), closeTo(11.17, 0.02));
      expect(d(1200, 1000, 11, 9), lessThan(d(1000, 1000, 11, 9)));
    });

    test('the underdog gains far more', () {
      expect(d(1000, 1200, 11, 9), greaterThan(30));
    });

    test('is antisymmetric, so ratings stay zero-sum', () {
      expect(d(1350, 990, 21, 13), -d(990, 1350, 13, 21));
      expect(d(1000, 1000, 7, 3), -d(1000, 1000, 3, 7));
    });
  });

  group('MOV damper', () {
    test('a bigger margin is worth more, up to the cap', () {
      final byOne = d(1000, 1000, 10, 9);
      final byThree = d(1000, 1000, 10, 7);
      final byTen = d(1000, 1000, 10, 0);
      expect(byThree, greaterThan(byOne));
      expect(byTen, greaterThan(byThree));
      expect(byTen, 32 * settings.movCap * 0.5);
    });

    test('a dominant winner is damped relative to an even one', () {
      final even = d(1000, 1000, 21, 11);
      final dominant = d(1600, 1000, 21, 11);
      expect(dominant, lessThan(even));
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
