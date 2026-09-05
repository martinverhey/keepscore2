import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/copyable.dart';

class JoinCodeCard extends StatelessWidget {
  const JoinCodeCard({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Copyable(
      text: code,
      builder: (context, copied, copy) => Container(
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
              label: copied
                  ? context.l10n.competitionCodeCopied
                  : context.l10n.commonCopy,
              kind: AdaptiveButtonKind.plain,
              expand: false,
              onPressed: copy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeLabel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code,
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
