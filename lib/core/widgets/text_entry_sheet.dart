import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/extensions/build_context.extension.dart';
import 'adaptive/adaptive.dart';
import 'sheet.dart';

Future<String?> showTextEntrySheet(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  required String submitLabel,
  String? subtitle,
  String initialValue = '',
  String? tooShortMessage,
}) {
  return showAdaptiveSheet<String>(
    context,
    builder: (sheetContext) => _TextEntrySheet(
      title: title,
      fieldLabel: fieldLabel,
      submitLabel: submitLabel,
      subtitle: subtitle,
      initialValue: initialValue,
      tooShortMessage: tooShortMessage,
    ),
  );
}

class _TextEntrySheet extends StatefulWidget {
  const _TextEntrySheet({
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    required this.subtitle,
    required this.initialValue,
    required this.tooShortMessage,
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;
  final String? subtitle;
  final String initialValue;
  final String? tooShortMessage;

  @override
  State<_TextEntrySheet> createState() => _TextEntrySheetState();
}

class _TextEntrySheetState extends State<_TextEntrySheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  late String _value = widget.initialValue;

  bool get _isValid => _value.trim().length >= 2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    Navigator.of(context).pop(_value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: widget.title,
      subtitle: widget.subtitle,
      content: AdaptiveTextField(
        label: widget.fieldLabel,
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        errorText: _value.isEmpty || _isValid ? null : widget.tooShortMessage,
        onChanged: (value) => setState(() => _value = value),
        onSubmitted: (_) => _submit(),
      ),
      primaryButton: AdaptiveButton(
        label: widget.submitLabel,
        onPressed: _isValid ? _submit : null,
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
