import 'package:flutter/widgets.dart';

import '../extensions/build_context_l10n.dart';
import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

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
            AdaptiveIcon(
              isGain ? AdaptiveGlyph.triangleUp : AdaptiveGlyph.triangleDown,
              color: color,
              size: 13,
            ),
            const SizedBox(width: 2),
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
