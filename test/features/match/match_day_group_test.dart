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

List<String> idsOf(MatchDayGroup group) =>
    group.matches.map((match) => match.id).toList();

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
      expect(idsOf(groups.first), ['a', 'b']);
      expect(groups.last.day, DateTime(2026, 8, 10));
      expect(idsOf(groups.last), ['c']);
    });

    test(
      'sorts entries within a day newest first, regardless of input order',
      () {
        final groups = groupByDay([
          matchAt('a', DateTime(2026, 8, 11, 9, 5)),
          matchAt('b', DateTime(2026, 8, 11, 21, 30)),
          matchAt('c', DateTime(2026, 8, 11, 14, 0)),
        ]);

        expect(idsOf(groups.single), ['b', 'c', 'a']);
      },
    );

    test('breaks a same-instant tie within a day deterministically, by id', () {
      final tied = DateTime(2026, 8, 11, 12);
      final groups = groupByDay([
        matchAt('a', tied),
        matchAt('c', tied),
        matchAt('b', tied),
      ]);

      expect(idsOf(groups.single), ['c', 'b', 'a']);
    });

    test('splits midnight-adjacent entries into their own days', () {
      final groups = groupByDay([
        matchAt('a', DateTime(2026, 8, 11, 0, 1)),
        matchAt('b', DateTime(2026, 8, 10, 23, 59)),
      ]);

      expect(groups.length, 2);
      expect(groups.map((group) => idsOf(group).single), ['a', 'b']);
    });

    test('orders the days newest first whatever order they arrive in', () {
      final groups = groupByDay([
        matchAt('a', DateTime(2026, 8, 11, 12)),
        matchAt('b', DateTime(2026, 8, 9, 12)),
        matchAt('c', DateTime(2026, 8, 10, 12)),
      ]);

      expect(groups.map((group) => group.day), [
        DateTime(2026, 8, 11),
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 9),
      ]);
    });

    test('has nothing to group when there are no matches', () {
      expect(groupByDay(const []), isEmpty);
    });
  });
}
