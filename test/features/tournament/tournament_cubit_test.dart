import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/tournament/domain/bracket.model.dart';
import 'package:keepscore2/features/tournament/domain/tournament.model.dart';
import 'package:keepscore2/features/tournament/domain/tournament_repository.dart';
import 'package:keepscore2/features/tournament/presentation/cubit/tournament_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Tournament _tournament({
  String id = 't1',
  TournamentStatus status = TournamentStatus.active,
  String? winnerPlayerId,
}) => Tournament(
  id: id,
  competitionId: 'c1',
  seasonId: 's1',
  size: 4,
  status: status,
  createdAt: DateTime(2026, 9, 11),
  winnerPlayerId: winnerPlayerId,
  createdBy: 'u-ada',
);

TournamentMatch _match(
  int round,
  int slot, {
  String? a,
  String? b,
  String? winner,
}) => TournamentMatch(
  id: 'm$round-$slot',
  tournamentId: 't1',
  round: round,
  slot: slot,
  playerA: a == null
      ? null
      : TournamentEntrant(playerId: a, displayName: a.toUpperCase()),
  playerB: b == null
      ? null
      : TournamentEntrant(playerId: b, displayName: b.toUpperCase()),
  winnerPlayerId: winner,
);

void _stubLoad(MockTournamentRepository repository) {
  when(() => repository.all('c1')).thenAnswer((_) async => [_tournament()]);
  when(
    () => repository.brackets('c1'),
  ).thenAnswer((_) async => {'t1': _bracket()});
}

Bracket _bracket() => Bracket.fromMatches([
  _match(1, 0, a: 'p1', b: 'p2'),
  _match(1, 1, a: 'p3', b: 'p4'),
  _match(2, 0),
]);

void main() {
  late MockTournamentRepository repository;
  late StreamController<void> tournamentTicks;
  late StreamController<void> bracketTicks;

  TournamentCubit build() => TournamentCubit(repository, 'c1');

  setUp(() {
    repository = MockTournamentRepository();
    tournamentTicks = StreamController<void>.broadcast();
    bracketTicks = StreamController<void>.broadcast();
    when(
      () => repository.watchTournaments('c1'),
    ).thenAnswer((_) => tournamentTicks.stream);
    when(
      () => repository.watchBracket(any()),
    ).thenAnswer((_) => bracketTicks.stream);
  });

  tearDown(() {
    tournamentTicks.close();
    bracketTicks.close();
  });

  test('reports missing when the competition has never run one', () async {
    when(() => repository.all('c1')).thenAnswer((_) async => []);
    when(() => repository.brackets('c1')).thenAnswer((_) async => {});

    final cubit = build();
    await cubit.load();

    expect(cubit.state, isA<TournamentMissing>());
    verifyNever(() => repository.watchBracket(any()));
    await cubit.close();
  });

  test('loads the bracket of the latest tournament', () async {
    _stubLoad(repository);

    final cubit = build();
    await cubit.load();

    final state = cubit.state as TournamentReady;
    expect(state.latest.id, 't1');
    expect(state.latest.bracket.roundCount, 2);
    expect(state.hasRunning, isTrue);
    await cubit.close();
  });

  test('every tournament keeps a run of its own, newest first', () async {
    when(() => repository.all('c1')).thenAnswer(
      (_) async => [
        _tournament(),
        _tournament(
          id: 't0',
          status: TournamentStatus.completed,
          winnerPlayerId: 'p1',
        ),
      ],
    );
    when(() => repository.brackets('c1')).thenAnswer(
      (_) async => {'t1': _bracket(), 't0': _bracket()},
    );

    final cubit = build();
    await cubit.load();

    final state = cubit.state as TournamentReady;
    expect(state.runs.map((run) => run.id), ['t1', 't0']);
    expect(state.runOf('t0')?.isCompleted, isTrue);
    verify(() => repository.watchBracket('t1')).called(1);
    verifyNever(() => repository.watchBracket('t0'));
    await cubit.close();
  });

  test('surfaces a load failure with no prior data', () async {
    when(() => repository.all('c1')).thenThrow(const UnknownFailure('boom'));
    when(() => repository.brackets('c1')).thenAnswer((_) async => {});

    final cubit = build();
    await cubit.load();

    expect(cubit.state, isA<TournamentFailed>());
    await cubit.close();
  });

  test('a silent refresh that fails keeps the data already on screen', () async {
    _stubLoad(repository);

    final cubit = build();
    await cubit.load();

    when(() => repository.all('c1')).thenThrow(const UnknownFailure('boom'));
    await cubit.refresh();

    expect(cubit.state, isA<TournamentReady>());
    await cubit.close();
  });

  test('a realtime tick on the bracket refetches', () async {
    _stubLoad(repository);

    final cubit = build();
    await cubit.load();
    clearInteractions(repository);

    bracketTicks.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _settle();

    verify(() => repository.all('c1')).called(greaterThanOrEqualTo(1));
    await cubit.close();
  });

  test('the bracket watcher is only rebuilt when the tournament changes', () async {
    _stubLoad(repository);

    final cubit = build();
    await cubit.load();
    await cubit.refresh();

    verify(() => repository.watchTournaments('c1')).called(1);
    verify(() => repository.watchBracket('t1')).called(1);
    await cubit.close();
  });

  test('setResult reloads and clears busy', () async {
    _stubLoad(repository);
    when(
      () => repository.setResult(
        tournamentMatchId: any(named: 'tournamentMatchId'),
        scoreA: any(named: 'scoreA'),
        scoreB: any(named: 'scoreB'),
      ),
    ).thenAnswer((_) async {});

    final cubit = build();
    await cubit.load();

    final saved = await cubit.setResult(
      tournamentMatchId: 'm1-0',
      scoreA: 21,
      scoreB: 15,
    );

    expect(saved, isTrue);
    expect((cubit.state as TournamentReady).busy, isFalse);
    await cubit.close();
  });

  test('a refused result lands on actionFailure, not a failed state', () async {
    _stubLoad(repository);
    when(
      () => repository.setResult(
        tournamentMatchId: any(named: 'tournamentMatchId'),
        scoreA: any(named: 'scoreA'),
        scoreB: any(named: 'scoreB'),
      ),
    ).thenThrow(const ValidationFailure('A tournament match needs a winner'));

    final cubit = build();
    await cubit.load();

    final saved = await cubit.setResult(
      tournamentMatchId: 'm1-0',
      scoreA: 11,
      scoreB: 11,
    );

    expect(saved, isFalse);
    final state = cubit.state as TournamentReady;
    expect(state.busy, isFalse);
    expect(state.actionFailure, isNotNull);
    await cubit.close();
  });
}
