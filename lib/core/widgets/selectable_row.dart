import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';
import 'check_mark.dart';

class SelectableRow extends StatelessWidget {
  const SelectableRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.labelColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AdaptiveColors.accent(context);

    return AdaptiveTappable(
      onTap: onTap,
      borderRadius: AppRadius.card,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: selected
              ? accent.withValues(alpha: AppOpacity.selectedFill)
              : AppColors.neutralSurface,
          border: Border.all(color: selected ? accent : AppColors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(color: labelColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CheckMark(selected: selected, color: accent),
          ],
        ),
      ),
    );
  }
}
