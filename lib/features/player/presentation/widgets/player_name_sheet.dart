import 'package:flutter/widgets.dart';

import '../../../../core/widgets/text_entry_sheet.dart';
import '../../../../l10n/app_localizations.dart';

Future<String?> showPlayerNameSheet(
  BuildContext context, {
  required String title,
  required String submitLabel,
  String? subtitle,
  String initialValue = '',
}) {
  final l10n = AppLocalizations.of(context);
  return showTextEntrySheet(
    context,
    title: title,
    fieldLabel: l10n.playersDisplayNameLabel,
    submitLabel: submitLabel,
    subtitle: subtitle,
    initialValue: initialValue,
    tooShortMessage: l10n.playersNameTooShort,
  );
}
