import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: _row(),
      ),
    );
  }

  Widget _row() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutralSurface,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyLarge)),
          trailing ??
              const AdaptiveIcon(
                AdaptiveGlyph.chevronRight,
                color: AppColors.neutral,
              ),
        ],
      ),
    );
  }
}
