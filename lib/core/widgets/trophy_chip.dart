import 'package:flutter/widgets.dart';

import '../extensions/build_context.extension.dart';
import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class TrophyChip extends StatelessWidget {
  const TrophyChip({
    super.key,
    required this.count,
    this.iconSize = 14,
    this.fontSize = AppTypography.captionSmallSize,
  });

  final int count;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.tournamentTrophies(count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveIcon(
              AdaptiveGlyph.trophy,
              color: AppColors.gold,
              size: iconSize,
            ),
            if (count > 1) ...[
              const SizedBox(width: 2),
              Text(
                '$count',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.gold,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
