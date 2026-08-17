import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.isWin, required this.label});

  final bool isWin;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = isWin ? AppColors.fireCore : AppColors.iceCore;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveIcon(
          isWin ? AdaptiveGlyph.fire : AdaptiveGlyph.ice,
          color: color,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.labelLarge.copyWith(color: color)),
      ],
    );
  }
}
