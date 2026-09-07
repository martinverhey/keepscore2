import 'package:flutter/widgets.dart';

import '../../features/profile/domain/streak_type.enum.dart';
import '../extensions/build_context.extension.dart';
import '../extensions/streak_type.extension.dart';
import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.type, required this.count});

  final StreakType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: type == StreakType.loss
          ? context.l10n.profileStreakLoss(count)
          : context.l10n.profileStreakWin(count),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            color: type.badgeFill(count),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < type.glyphCount(count); i++) ...[
                if (i > 0) const SizedBox(width: 2),
                AdaptiveIcon(
                  type.glyph,
                  color: type.glyphColor(count),
                  size: 13,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
