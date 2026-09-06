import 'package:flutter/widgets.dart';

import '../extensions/build_context.extension.dart';
import '../extensions/int.extension.dart';
import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.tier, required this.count});

  final int tier;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.profileStreakWin(count),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            color: tier.flameBadgeFill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tier.flameCount; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                AdaptiveIcon(
                  AdaptiveGlyph.fire,
                  color: tier.flameColor,
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
