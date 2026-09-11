import 'package:bloc/bloc.dart';

import '../../../../core/data/planned_match_store.dart';
import '../../domain/planned_match.model.dart';
import 'planned_match_state.dart';

export 'planned_match_state.dart';

class PlannedMatchCubit extends Cubit<PlannedMatchState> {
  PlannedMatchCubit() : super(const PlannedMatchLoading());

  String? _competitionId;

  Future<void> select(String competitionId) async {
    if (_competitionId == competitionId) return;
    _competitionId = competitionId;
    emit(const PlannedMatchLoading());

    final matches = await PlannedMatchStore.get(competitionId);
    if (isClosed || competitionId != _competitionId) return;
    emit(PlannedMatchReady(competitionId: competitionId, matches: matches));
  }

  Future<void> plan(Iterable<String> playerIds) async {
    final competitionId = _competitionId;
    if (competitionId == null) return;

    final planned = state.matches;
    final known = {for (final match in planned) match.pairKey};
    final added = [
      for (final pair in _roundRobin(playerIds.toList(growable: false)))
        if (known.add(pair.pairKey)) pair,
    ];
    if (added.isEmpty) return;

    await _write(competitionId, _spreadOverRounds([...planned, ...added]));
  }

  Future<void> remove(PlannedMatch match) async {
    final competitionId = _competitionId;
    if (competitionId == null) return;

    final remaining = [
      for (final planned in state.matches)
        if (planned.pairKey != match.pairKey) planned,
    ];
    if (remaining.length == state.matches.length) return;

    await _write(competitionId, remaining);
  }

  Future<void> clear() async {
    final competitionId = _competitionId;
    if (competitionId == null || state.matches.isEmpty) return;
    await _write(competitionId, const []);
  }

  Future<void> _write(String competitionId, List<PlannedMatch> matches) async {
    emit(PlannedMatchReady(competitionId: competitionId, matches: matches));
    await PlannedMatchStore.set(competitionId, matches);
  }
}

List<PlannedMatch> _roundRobin(List<String> playerIds) {
  return [
    for (var first = 0; first < playerIds.length; first++)
      for (var second = first + 1; second < playerIds.length; second++)
        PlannedMatch(
          playerAId: playerIds[first],
          playerBId: playerIds[second],
        ),
  ];
}

List<PlannedMatch> _spreadOverRounds(List<PlannedMatch> matches) {
  final remaining = [...matches];
  final pairsLeft = <String, int>{};
  for (final match in remaining) {
    pairsLeft.update(match.playerAId, (count) => count + 1, ifAbsent: () => 1);
    pairsLeft.update(match.playerBId, (count) => count + 1, ifAbsent: () => 1);
  }

  final ordered = <PlannedMatch>[];
  while (remaining.isNotEmpty) {
    final playing = <String>{};

    for (
      var index = _busiestFreePair(remaining, playing, pairsLeft);
      index != null;
      index = _busiestFreePair(remaining, playing, pairsLeft)
    ) {
      final match = remaining.removeAt(index);
      playing.add(match.playerAId);
      playing.add(match.playerBId);
      pairsLeft.update(match.playerAId, (count) => count - 1);
      pairsLeft.update(match.playerBId, (count) => count - 1);
      ordered.add(match);
    }
  }

  return ordered;
}

int? _busiestFreePair(
  List<PlannedMatch> remaining,
  Set<String> playing,
  Map<String, int> pairsLeft,
) {
  int? busiest;
  var mostLeft = 0;

  for (var index = 0; index < remaining.length; index++) {
    final match = remaining[index];
    if (playing.contains(match.playerAId) ||
        playing.contains(match.playerBId)) {
      continue;
    }

    final left = pairsLeft[match.playerAId]! + pairsLeft[match.playerBId]!;
    if (left > mostLeft) {
      mostLeft = left;
      busiest = index;
    }
  }

  return busiest;
}
