import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/extensions/build_context_locale.dart';
import 'match_day_group.dart';

String matchDayLabel(BuildContext context, DateTime day, {DateTime? now}) {
  final today = dayOf(now ?? DateTime.now());
  final difference = today.difference(day).inDays;

  if (difference == 0) return context.l10n.matchDayToday;
  if (difference == 1) return context.l10n.matchDayYesterday;

  return day.year == today.year
      ? DateFormat.MMMMEEEEd(context.languageTag).format(day)
      : DateFormat.yMMMMEEEEd(context.languageTag).format(day);
}
