import 'package:flutter/widgets.dart';

import '../../features/profile/domain/streak_type.enum.dart';
import '../theme/app_tokens.dart';
import '../widgets/adaptive/adaptive.dart';

extension StreakTypeTier on StreakType {
  int tier(int count) {
    if (this == StreakType.none) return 0;
    if (count >= 25) return 4;
    if (count >= 10) return 3;
    if (count >= 5) return 2;
    if (count >= 3) return 1;
    return 0;
  }

  bool hasBadge(int count) => tier(count) > 0;
}

extension StreakTypeBadge on StreakType {
  AdaptiveGlyph get glyph =>
      this == StreakType.loss ? AdaptiveGlyph.ice : AdaptiveGlyph.fire;

  int glyphCount(int count) {
    final tier = this.tier(count);
    return tier >= 4 ? 1 : tier;
  }

  Color glyphColor(int count) => switch (this) {
    StreakType.loss => tier(count) >= 4
        ? AppColors.iceEliteCore
        : AppColors.iceCore,
    _ => tier(count) >= 4 ? AppColors.fireEliteCore : AppColors.fireCore,
  };

  Color badgeFill(int count) => switch (this) {
    StreakType.loss => tier(count) >= 4
        ? AppColors.iceEliteBadgeFill
        : AppColors.iceBadgeFill,
    _ => tier(count) >= 4
        ? AppColors.fireEliteBadgeFill
        : AppColors.fireBadgeFill,
  };
}
