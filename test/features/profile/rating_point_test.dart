import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/profile/domain/rating_point.model.dart';

void main() {
  test('reads the rating off the embedded participation, not the match', () {
    final point = RatingPoint.fromMap({
      'played_at': '2026-08-31T18:19:12.371622Z',
      'match_players': [
        {'rating_after': '1357.01', 'rating_delta': 6.48},
      ],
    });

    expect(point.ratingAfter, 1357.01);
    expect(point.ratingDelta, 6.48);
    expect(
      point.playedAt.toUtc(),
      DateTime.utc(2026, 8, 31, 18, 19, 12, 371, 622),
    );
  });
}
