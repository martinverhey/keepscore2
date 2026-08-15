import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/presentation/widgets/match_day_group.dart';

MatchEntry matchAt(String id, DateTime playedAt) => MatchEntry(
  id: id,
  competitionId: 'c1',
  seasonId: 's1',
  playedAt: playedAt,
  teamAScore: 11,
  teamBScore: 9,
  teamARating: 1000,
  teamBRating: 1000,
  teamA: const [],
  teamB: const [],
);

void main() {
  group('groupByDay', () {
    test('keeps matches from one calendar day together', () {
      final groups = groupByDay([
        matchAt('a', DateTime(2026, 8, 11, 21, 30)),
        matchAt('b', DateTime(2026, 8, 11, 9, 5)),
        matchAt('c', DateTime(2026, 8, 10, 18, 0)),
      ]);

      expect(groups.length, 2);
      expect(groups.first.day, DateTime(2026, 8, 11));
      expect(groups.first.matches.map((m) => m.id), ['a', 'b']);
      expect(groups.last.day, DateTime(2026, 8, 10));
      expect(groups.last.matches.map((m) => m.id), ['c']);
    });

    test('splits midnight-adjacent matches into their own days', () {
      final groups = groupByDay([
        matchAt('a', DateTime(2026, 8, 11, 0, 1)),
        matchAt('b', DateTime(2026, 8, 10, 23, 59)),
      ]);

      expect(groups.length, 2);
      expect(groups.map((g) => g.matches.single.id), ['a', 'b']);
    });

    test('preserves the order it was given', () {
      final groups = groupByDay([
        matchAt('a', DateTime(2026, 8, 11, 12)),
        matchAt('b', DateTime(2026, 8, 9, 12)),
        matchAt('c', DateTime(2026, 8, 10, 12)),
      ]);

      expect(groups.map((g) => g.day), [
        DateTime(2026, 8, 11),
        DateTime(2026, 8, 9),
        DateTime(2026, 8, 10),
      ]);
    });

    test('has nothing to group when there are no matches', () {
      expect(groupByDay(const []), isEmpty);
    });
  });
}
