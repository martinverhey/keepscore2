import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'build_context.extension.dart';

extension DateTimeDayOnly on DateTime {
  DateTime get dayOnly => DateTime(year, month, day);
}

extension DateTimeShortDayLabel on DateTime {
  String shortDayLabel(BuildContext context) =>
      DateFormat.MMMd(context.languageTag).format(this);
}

extension DateTimeMatchDayLabel on DateTime {
  String matchDayLabel(BuildContext context, {DateTime? now}) {
    final today = (now ?? DateTime.now()).dayOnly;
    final difference = today.difference(this).inDays;

    if (difference == 0) return context.l10n.matchDayToday;
    if (difference == 1) return context.l10n.matchDayYesterday;

    return year == today.year
        ? DateFormat.MMMMEEEEd(context.languageTag).format(this)
        : DateFormat.yMMMMEEEEd(context.languageTag).format(this);
  }
}

extension DateTimeLastPlayedLabel on DateTime {
  static const int _recentDays = 7;

  String lastPlayedLabel(BuildContext context, {DateTime? now}) {
    final today = (now ?? DateTime.now()).dayOnly;
    final playedOn = toLocal().dayOnly;
    final difference = today.difference(playedOn).inDays;

    if (difference <= 0) return context.l10n.competitionPlayedToday;
    if (difference == 1) return context.l10n.competitionPlayedYesterday;
    if (difference < _recentDays) {
      return context.l10n.competitionPlayedDaysAgo(difference);
    }

    final date = playedOn.year == today.year
        ? DateFormat.MMMd(context.languageTag).format(playedOn)
        : DateFormat.yMMMd(context.languageTag).format(playedOn);
    return context.l10n.competitionPlayedOn(date);
  }
}
