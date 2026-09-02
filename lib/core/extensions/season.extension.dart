import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../features/competition/domain/competition.model.dart';
import '../../features/leaderboard/domain/season.model.dart';
import '../../l10n/app_localizations.dart';
import 'build_context.extension.dart';

extension SeasonLabel on Season {
  String label(BuildContext context, SeasonLength length) {
    final at = midpoint;

    return switch (length) {
      SeasonLength.monthly => DateFormat.yMMMM(context.languageTag).format(at),
      SeasonLength.quarterly => AppLocalizations.of(
        context,
      ).seasonQuarterLabel(((at.month - 1) ~/ 3) + 1, '${at.year}'),
      SeasonLength.yearly => '${at.year}',
    };
  }
}

extension SeasonRangeLabel on Season {
  String rangeLabel(BuildContext context) {
    final tag = context.languageTag;
    const insideTheDay = Duration(hours: 12);

    return AppLocalizations.of(context).seasonRange(
      DateFormat.MMMd(tag).format(startsAt.add(insideTheDay)),
      DateFormat.yMMMd(tag).format(endsAt.subtract(insideTheDay)),
    );
  }
}
