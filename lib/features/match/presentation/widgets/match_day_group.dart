import 'package:equatable/equatable.dart';

import '../../domain/match_entry.dart';

class MatchDayGroup extends Equatable {
  const MatchDayGroup({required this.day, required this.matches});

  final DateTime day;
  final List<MatchEntry> matches;

  @override
  List<Object?> get props => [day, matches];
}

DateTime dayOf(DateTime at) => DateTime(at.year, at.month, at.day);

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

  return groups;
}
