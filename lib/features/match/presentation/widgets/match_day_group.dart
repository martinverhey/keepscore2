import 'package:equatable/equatable.dart';

import '../../../../core/extensions/date_time.extension.dart';
import 'match_feed_entry.dart';

class MatchDayGroup extends Equatable {
  const MatchDayGroup({required this.day, required this.entries});

  final DateTime day;
  final List<MatchFeedEntry> entries;

  @override
  List<Object?> get props => [day, entries];
}

List<MatchDayGroup> groupByDay(List<MatchFeedEntry> entries) {
  final newestFirst = [...entries]..sort(_newestFirst);
  final groups = <MatchDayGroup>[];

  for (final entry in newestFirst) {
    final day = entry.happenedAt.dayOnly;
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.entries.add(entry);
    } else {
      groups.add(MatchDayGroup(day: day, entries: [entry]));
    }
  }

  return groups;
}

int _newestFirst(MatchFeedEntry a, MatchFeedEntry b) {
  final byTime = b.happenedAt.compareTo(a.happenedAt);
  return byTime != 0 ? byTime : b.id.compareTo(a.id);
}
