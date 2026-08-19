import 'package:flutter/widgets.dart';

import '../extensions/build_context.extension.dart';
import '../theme/app_tokens.dart';
import 'triangle_icon.dart';

class TodayDeltaBadge extends StatelessWidget {
  const TodayDeltaBadge({super.key, required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final isGain = delta > 0;
    final color = isGain ? AppColors.positive : AppColors.negative;
    final amount = delta.abs().toStringAsFixed(1);

    return Semantics(
      label: isGain
          ? context.l10n.leaderboardTodayGain(amount)
          : context.l10n.leaderboardTodayLoss(amount),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TriangleIcon(pointsUp: isGain, color: color, size: 10),
            const SizedBox(width: 2),
            Text(
              amount,
              style: AppTypography.captionSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
