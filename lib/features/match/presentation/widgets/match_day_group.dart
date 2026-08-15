import 'package:equatable/equatable.dart';

import '../../domain/match_entry.model.dart';

class MatchDayGroup extends Equatable {
  const MatchDayGroup({required this.day, required this.matches});

  final DateTime day;
  final List<MatchEntry> matches;

  @override
  List<Object?> get props => [day, matches];
}

DateTime dayOf(DateTime at) => DateTime(at.year, at.month, at.day);

int _newestFirst(MatchEntry a, MatchEntry b) {
  final byTime = b.playedAt.compareTo(a.playedAt);
  return byTime != 0 ? byTime : b.id.compareTo(a.id);
}

List<MatchDayGroup> groupByDay(List<MatchEntry> matches) {
  final groups = <MatchDayGroup>[];

  for (final match in matches) {
    final day = dayOf(match.playedAt);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.matches.add(match);
    } else {
      groups.add(MatchDayGroup(day: day, matches: [match]));
    }
  }

  for (final group in groups) {
    group.matches.sort(_newestFirst);
  }

  return groups;
}
