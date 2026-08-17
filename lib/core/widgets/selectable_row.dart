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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

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
              ? accent.withValues(alpha: 0.14)
              : AppColors.neutral.withValues(alpha: 0.08),
          border: Border.all(
            color: selected ? accent : const Color(0x00000000),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge,
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
