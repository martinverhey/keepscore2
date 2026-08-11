import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';
import '../../l10n/app_localizations.dart';

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
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
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
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.subtitle!,
                style: const TextStyle(color: AppColors.neutral, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            AdaptiveTextField(
              label: widget.fieldLabel,
              controller: _controller,
              autofocus: true,
              maxLength: 60,
              textInputAction: TextInputAction.done,
              errorText: _value.isEmpty || _isValid
                  ? null
                  : widget.tooShortMessage,
              onChanged: (value) => setState(() => _value = value),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),

            AdaptiveButton(
              label: widget.submitLabel,
              onPressed: _isValid ? _submit : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: l10n.commonCancel,
              kind: AdaptiveButtonKind.plain,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
