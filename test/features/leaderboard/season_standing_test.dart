import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/leaderboard/domain/medal.dart';
import 'package:keepscore2/features/leaderboard/domain/medals.dart';
import 'package:keepscore2/features/leaderboard/domain/season_standing.dart';

Map<String, dynamic> _row({Object? medal = 'gold'}) => {
  'season_id': 's1',
  'competition_id': 'c1',
  'player_id': 'p1',
  'display_name': 'Ada',
  'is_claimed': true,
  'rating': 1080,
  'played': 5,
  'wins': 4,
  'losses': 1,
  'draws': 0,
  'rank': 1,
  'starts_at': '2026-06-30T22:00:00+00:00',
  'ends_at': '2026-07-31T22:00:00+00:00',
  'medal': medal,
};

void main() {
  test('reads a season_history row, medal included', () {
    final standing = SeasonStanding.fromMap(_row());

    expect(standing.playerId, 'p1');
    expect(standing.rank, 1);
    expect(standing.medal, Medal.gold);
    expect(standing.season.id, 's1');
  });

  test('a row outside the top three has no medal', () {
    final standing = SeasonStanding.fromMap(_row(medal: null));

    expect(standing.medal, isNull);
  });

  test('Medals reads gold/silver/bronze counts', () {
    final tally = Medals.fromMap({
      'player_id': 'p1',
      'gold': 2,
      'silver': 0,
      'bronze': 1,
    });

    expect(tally.gold, 2);
    expect(tally.hasAny, isTrue);
  });

  test('a tally with nothing won reports hasAny as false', () {
    final tally = Medals.fromMap({
      'player_id': 'p1',
      'gold': 0,
      'silver': 0,
      'bronze': 0,
    });

    expect(tally.hasAny, isFalse);
  });
}
