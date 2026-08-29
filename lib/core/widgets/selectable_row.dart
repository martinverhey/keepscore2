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
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

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
            Expanded(child: _label()),
            CheckMark(selected: selected, color: accent),
          ],
        ),
      ),
    );
  }

  Widget _label() {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing case final trailing?) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing,
        ],
      ],
    );
  }
}
