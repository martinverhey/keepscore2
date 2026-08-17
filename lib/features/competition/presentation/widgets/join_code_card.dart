import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class JoinCodeCard extends StatefulWidget {
  const JoinCodeCard({super.key, required this.code});
  final String code;

  @override
  State<JoinCodeCard> createState() => _JoinCodeCardState();
}

class _JoinCodeCardState extends State<JoinCodeCard> {
  Timer? _resetCopied;
  bool _copied = false;

  @override
  void dispose() {
    _resetCopied?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetCopied?.cancel();
    _resetCopied = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AdaptiveColors.accent(
          context,
        ).withValues(alpha: AppOpacity.accentFill),
      ),
      child: Row(
        children: [
          Expanded(child: _codeLabel(context)),
          AdaptiveButton(
            label: _copied
                ? context.l10n.competitionCodeCopied
                : context.l10n.commonCopy,
            kind: AdaptiveButtonKind.plain,
            expand: false,
            onPressed: _copy,
          ),
        ],
      ),
    );
  }

  Widget _codeLabel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.code,
          style: AppTypography.headlineMedium.copyWith(
            fontFeatures: AppTypography.tabularFigures,
            letterSpacing: 3,
            color: AdaptiveColors.accent(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(context.l10n.competitionCodeHelp, style: AppTypography.caption),
      ],
    );
  }
}
