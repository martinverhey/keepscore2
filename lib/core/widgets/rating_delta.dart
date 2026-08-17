import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

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
    return Text(
      _formatDelta(value),
      style: AppTypography.bodySmall.copyWith(
        color: _deltaColor(value),
        fontSize: fontSize,
        fontFeatures: AppTypography.tabularFigures,
      ),
    );
  }
}

String _formatDelta(double value) {
  final rounded = (value * 10).round() / 10;
  final magnitude = rounded.abs().toStringAsFixed(1);
  if (rounded > 0) return '+$magnitude';
  if (rounded < 0) return '-$magnitude';
  return '0.0';
}

Color _deltaColor(double value) {
  if (value > 0) return AppColors.positive;
  if (value < 0) return AppColors.negative;
  return AppColors.neutral;
}
