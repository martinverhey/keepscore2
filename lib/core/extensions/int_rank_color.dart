import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

extension IntRankColor on int {
  Color? get rankColor => switch (this) {
    1 => AppColors.gold,
    2 => AppColors.silver,
    3 => AppColors.bronze,
    _ => null,
  };
}
