import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';

Map<String, dynamic> _row({Object? teamARating = 1002.5}) => {
  'id': 'm1',
  'competition_id': 'c1',
  'season_id': 's1',
  'played_at': '2026-08-09T18:30:00+00:00',
  'team_a_score': 11,
  'team_b_score': 7,
  'team_a_rating': teamARating,
  'team_b_rating': 990,
  'created_by': 'u1',
  'team_a': [
    {
      'player_id': 'p1',
      'display_name': 'Ada',
      'rating_before': 1005,
      'rating_delta': 8.4,
    },
    {
      'player_id': 'p2',
      'display_name': 'Grace',
      'rating_before': 1000,
      'rating_delta': 8.4,
    },
  ],
  'team_b': [
    {
      'player_id': 'p3',
      'display_name': 'Zoe',
      'rating_before': '990',
      'rating_delta': '-8.4',
    },
  ],
};

void main() {
  test('reads a match_feed row, players and all', () {
    final match = MatchEntry.fromMap(_row());

    expect(match.id, 'm1');
    expect(match.teamA.map((entry) => entry.displayName), ['Ada', 'Grace']);
    expect(match.teamB.single.playerId, 'p3');
    expect(match.winner, MatchTeam.a);
    expect(match.isDraw, isFalse);
    expect(match.deltaA, 8.4);
    expect(match.teamA.first.ratingAfter, closeTo(1013.4, 0.001));
  });

  test('numeric columns arrive as either JSON numbers or strings', () {
    expect(MatchEntry.fromMap(_row(teamARating: '1002.5')).teamARating, 1002.5);
    expect(MatchEntry.fromMap(_row()).teamARating, 1002.5);
    expect(MatchEntry.fromMap(_row()).teamB.single.ratingDelta, -8.4);
  });

  test('equal scores are a draw with no winner', () {
    final match = MatchEntry.fromMap({
      ..._row(),
      'team_a_score': 7,
      'team_b_score': 7,
    });

    expect(match.isDraw, isTrue);
    expect(match.winner, isNull);
  });

  test('only the person who logged it, or the owner, may manage it', () {
    final match = MatchEntry.fromMap(_row());

    expect(match.isManageableBy('u1', ownerId: 'u9'), isTrue);
    expect(match.isManageableBy('u9', ownerId: 'u9'), isTrue);
    expect(match.isManageableBy('u2', ownerId: 'u9'), isFalse);
    expect(match.isManageableBy(null, ownerId: 'u9'), isFalse);
  });
}
