import 'package:flutter/widgets.dart';

import '../../features/profile/domain/rating_point.model.dart';
import '../theme/app_tokens.dart';
import '../widgets/adaptive/adaptive.dart';

extension RatingPointListTrend on List<RatingPoint> {
  Color trendColor(BuildContext context) {
    final change = last.ratingAfter - first.ratingAfter;
    if (change > 0) return AppColors.positive;
    if (change < 0) return AppColors.negative;
    return AdaptiveColors.accent(context);
  }

  List<double> get ratings => [for (final point in this) point.ratingAfter];
}
