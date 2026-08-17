import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/text_entry_sheet.dart';

Future<String?> showPlayerNameSheet(
  BuildContext context, {
  required String title,
  required String submitLabel,
  String? subtitle,
  String initialValue = '',
}) {
  return showTextEntrySheet(
    context,
    title: title,
    fieldLabel: context.l10n.playersDisplayNameLabel,
    submitLabel: submitLabel,
    subtitle: subtitle,
    initialValue: initialValue,
    tooShortMessage: context.l10n.playersNameTooShort,
  );
}
