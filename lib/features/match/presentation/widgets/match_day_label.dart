import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import 'match_day_group.dart';

String matchDayLabel(BuildContext context, DateTime day, {DateTime? now}) {
  final l10n = AppLocalizations.of(context);
  final today = dayOf(now ?? DateTime.now());
  final difference = today.difference(day).inDays;

  if (difference == 0) return l10n.matchDayToday;
  if (difference == 1) return l10n.matchDayYesterday;

  final locale = Localizations.localeOf(context).toLanguageTag();
  return day.year == today.year
      ? DateFormat.MMMMEEEEd(locale).format(day)
      : DateFormat.yMMMMEEEEd(locale).format(day);
}
