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
