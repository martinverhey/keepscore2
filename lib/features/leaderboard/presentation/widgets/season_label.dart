import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../competition/domain/competition.model.dart';
import '../../domain/season.model.dart';

String seasonLabel(BuildContext context, Season season, SeasonLength length) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final at = season.midpoint;

  return switch (length) {
    SeasonLength.monthly => DateFormat.yMMMM(locale).format(at),
    SeasonLength.quarterly => AppLocalizations.of(
      context,
    ).seasonQuarterLabel(((at.month - 1) ~/ 3) + 1, '${at.year}'),
    SeasonLength.yearly => '${at.year}',
  };
}
