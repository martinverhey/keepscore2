import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class HintCard extends StatelessWidget {
  const HintCard({
    super.key,
    this.badge,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final Widget? badge;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutralSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[badge!, const SizedBox(height: AppSpacing.sm)],
          Text(message, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: actionLabel,
            kind: AdaptiveButtonKind.tinted,
            expand: false,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
