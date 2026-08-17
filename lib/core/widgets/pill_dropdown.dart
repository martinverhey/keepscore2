import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class PillDropdown extends StatelessWidget {
  const PillDropdown({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.accent(context);

    return AdaptiveTappable(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: AppOpacity.accentFill),
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: accent.withValues(alpha: AppOpacity.accentBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(color: accent),
            ),
            const SizedBox(width: 2),
            AdaptiveIcon(AdaptiveGlyph.chevronDown, color: accent, size: 16),
          ],
        ),
      ),
    );
  }
}
