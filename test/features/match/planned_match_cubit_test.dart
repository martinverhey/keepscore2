import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/planned_match.model.dart';
import 'package:keepscore2/features/match/presentation/cubit/planned_match_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

PlannedMatchCubit _cubit() {
  final cubit = PlannedMatchCubit();
  addTearDown(cubit.close);
  return cubit;
}

int _longestRunOf(String playerId, List<PlannedMatch> matches) {
  var longest = 0;
  var run = 0;

  for (final match in matches) {
    final plays = match.playerAId == playerId || match.playerBId == playerId;
    run = plays ? run + 1 : 0;
    if (run > longest) longest = run;
  }

  return longest;
}

void _expectNobodyPlaysThriceInARow(
  List<String> playerIds,
  List<PlannedMatch> matches,
) {
  for (final playerId in playerIds) {
    expect(
      _longestRunOf(playerId, matches),
      lessThanOrEqualTo(2),
      reason: '$playerId plays too many times in a row',
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('pre-picking players plans every pairing between them', () async {
    final cubit = _cubit();
    await cubit.select('c1');

    await cubit.plan(['p1', 'p2', 'p3']);

    expect(cubit.state.matches, const [
      PlannedMatch(playerAId: 'p1', playerBId: 'p2'),
      PlannedMatch(playerAId: 'p1', playerBId: 'p3'),
      PlannedMatch(playerAId: 'p2', playerBId: 'p3'),
    ]);
  });

  test('nobody plays more than twice in a row', () async {
    for (final size in [4, 5, 6, 7, 8]) {
      SharedPreferences.setMockInitialValues(const {});
      final playerIds = [for (var i = 1; i <= size; i++) 'p$i'];
      final cubit = _cubit();
      await cubit.select('c$size');

      await cubit.plan(playerIds);

      expect(cubit.state.matches.length, size * (size - 1) ~/ 2);
      _expectNobodyPlaysThriceInARow(playerIds, cubit.state.matches);
    }
  });

  test('pre-picking again re-spaces the pairings already planned', () async {
    final cubit = _cubit();
    await cubit.select('c1');
    await cubit.plan(['p1', 'p2', 'p3']);

    await cubit.plan(['p1', 'p2', 'p3', 'p4', 'p5']);

    expect(cubit.state.matches.length, 10);
    _expectNobodyPlaysThriceInARow([
      'p1',
      'p2',
      'p3',
      'p4',
      'p5',
    ], cubit.state.matches);
  });

  test('two pre-picks of separate players still interleave', () async {
    final cubit = _cubit();
    await cubit.select('c1');
    await cubit.plan(['p1', 'p2', 'p3']);

    await cubit.plan(['p4', 'p5', 'p6']);

    expect(cubit.state.matches.length, 6);
    _expectNobodyPlaysThriceInARow([
      'p1',
      'p2',
      'p3',
      'p4',
      'p5',
      'p6',
    ], cubit.state.matches);
  });

  test('pre-picking fewer than two players plans nothing', () async {
    final cubit = _cubit();
    await cubit.select('c1');

    await cubit.plan(['p1']);

    expect(cubit.state.matches, isEmpty);
  });

  test('pre-picking again adds only the pairings that are missing', () async {
    final cubit = _cubit();
    await cubit.select('c1');
    await cubit.plan(['p1', 'p2']);

    await cubit.plan(['p2', 'p1', 'p3']);

    expect(cubit.state.matches, const [
      PlannedMatch(playerAId: 'p1', playerBId: 'p2'),
      PlannedMatch(playerAId: 'p2', playerBId: 'p3'),
      PlannedMatch(playerAId: 'p1', playerBId: 'p3'),
    ]);
  });

  test('removing a pairing ignores which side each player was on', () async {
    final cubit = _cubit();
    await cubit.select('c1');
    await cubit.plan(['p1', 'p2', 'p3']);

    await cubit.remove(const PlannedMatch(playerAId: 'p3', playerBId: 'p1'));

    expect(cubit.state.matches, const [
      PlannedMatch(playerAId: 'p1', playerBId: 'p2'),
      PlannedMatch(playerAId: 'p2', playerBId: 'p3'),
    ]);
  });

  test('clearing drops every pairing', () async {
    final cubit = _cubit();
    await cubit.select('c1');
    await cubit.plan(['p1', 'p2', 'p3']);

    await cubit.clear();

    expect(cubit.state.matches, isEmpty);
  });

  test('planned pairings come back on the next launch', () async {
    final first = _cubit();
    await first.select('c1');
    await first.plan(['p1', 'p2']);

    final second = _cubit();
    await second.select('c1');

    expect(second.state.matches, const [
      PlannedMatch(playerAId: 'p1', playerBId: 'p2'),
    ]);
  });

  test('each competition keeps its own pairings', () async {
    final cubit = _cubit();
    await cubit.select('c1');
    await cubit.plan(['p1', 'p2']);

    await cubit.select('c2');

    expect(cubit.state.matches, isEmpty);

    await cubit.select('c1');

    expect(cubit.state.matches, const [
      PlannedMatch(playerAId: 'p1', playerBId: 'p2'),
    ]);
  });
}
