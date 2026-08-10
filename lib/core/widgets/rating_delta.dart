import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

String formatRating(double value) => value.round().toString();

String formatDelta(double value) {
  final rounded = (value * 10).round() / 10;
  final magnitude = rounded.abs().toStringAsFixed(1);
  if (rounded > 0) return '+$magnitude';
  if (rounded < 0) return '-$magnitude';
  return '0.0';
}

Color deltaColor(double value) {
  if (value > 0) return AppColors.positive;
  if (value < 0) return AppColors.negative;
  return AppColors.neutral;
}

/// The rating change a match produced, in the sign and colour a player reads
/// first. Figures are tabular so a column of these lines up.
class RatingDelta extends StatelessWidget {
  const RatingDelta({super.key, required this.value, this.fontSize = 14});

  final double value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatDelta(value),
      style: TextStyle(
        color: deltaColor(value),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
