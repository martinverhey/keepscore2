import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AdaptiveColors.accent(context).withValues(alpha: 0.10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.code,
                  style: TextStyle(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AdaptiveColors.accent(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.competitionCodeHelp,
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          AdaptiveButton(
            label: _copied ? l10n.competitionCodeCopied : l10n.commonCopy,
            kind: AdaptiveButtonKind.plain,
            expand: false,
            onPressed: _copy,
          ),
        ],
      ),
    );
  }
}
