import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class MedalChip extends StatelessWidget {
  const MedalChip({
    super.key,
    required this.color,
    required this.count,
    this.iconSize = 14,
    this.fontSize = AppTypography.captionSmallSize,
  });

  final Color color;
  final int count;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveIcon(AdaptiveGlyph.medal, color: color, size: iconSize),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: AppTypography.captionSmall.copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}
