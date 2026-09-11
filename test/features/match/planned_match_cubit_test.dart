import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/planned_match.model.dart';
import 'package:keepscore2/features/match/presentation/cubit/planned_match_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

PlannedMatchCubit _cubit() {
  final cubit = PlannedMatchCubit();
  addTearDown(cubit.close);
  return cubit;
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
