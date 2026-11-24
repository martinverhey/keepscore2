import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class DisclosureRow extends StatelessWidget {
  static const Duration _turnDuration = Duration(milliseconds: 200);

  const DisclosureRow({
    super.key,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: expanded,
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: _row(),
      ),
    );
  }

  Widget _row() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
          ),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: _turnDuration,
            child: const AdaptiveIcon(
              AdaptiveGlyph.chevronDown,
              color: AppColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}
