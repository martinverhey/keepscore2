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

extension IntFlameTier on int {
  int get flameCount => this >= 4 ? 1 : this;

  Color get flameColor =>
      this >= 4 ? AppColors.fireEliteCore : AppColors.fireCore;

  Color get flameBadgeFill =>
      this >= 4 ? AppColors.fireEliteBadgeFill : AppColors.fireBadgeFill;
}
