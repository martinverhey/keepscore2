import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'triangle_icon.dart';

class RatingDelta extends StatelessWidget {
  const RatingDelta({
    super.key,
    required this.value,
    this.fontSize = AppTypography.bodySmallSize,
  });

  final double value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final rounded = (value * 10).round() / 10;
    final color = _deltaColor(rounded);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rounded != 0) ...[
          TriangleIcon(pointsUp: rounded > 0, color: color, size: fontSize - 2),
          const SizedBox(width: 2),
        ],
        Text(
          rounded.abs().toStringAsFixed(1),
          style: AppTypography.bodySmall.copyWith(
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

Color _deltaColor(double value) {
  if (value > 0) return AppColors.positive;
  if (value < 0) return AppColors.negative;
  return AppColors.neutral;
}
