import 'package:flutter/widgets.dart';

import '../extensions/build_context.extension.dart';
import '../theme/app_tokens.dart';
import 'rating_delta.dart';

class TodayDeltaBadge extends StatelessWidget {
  const TodayDeltaBadge({super.key, required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final amount = delta.abs().toStringAsFixed(1);

    return Semantics(
      label: delta > 0
          ? context.l10n.leaderboardTodayGain(amount)
          : context.l10n.leaderboardTodayLoss(amount),
      child: ExcludeSemantics(
        child: RatingDelta(
          value: delta,
          fontSize: AppTypography.captionSmallSize,
        ),
      ),
    );
  }
}
