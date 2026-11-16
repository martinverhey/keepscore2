import 'package:flutter/widgets.dart';

import '../../features/profile/domain/streak_type.enum.dart';
import '../theme/app_tokens.dart';
import '../widgets/adaptive/adaptive.dart';

extension StreakTypeTier on StreakType {
  int tier(int count) {
    if (this == StreakType.none) return 0;
    if (count >= 50) return 4;
    if (count >= 25) return 3;
    if (count >= 10) return 2;
    if (count >= 5) return 1;
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

  Color glyphColor(BuildContext context, int count) =>
      switch ((this, tier(count))) {
        (StreakType.loss, >= 4) => AdaptiveColors.iceElite(context),
        (StreakType.loss, _) => AppColors.iceCore,
        (_, >= 4) => AppColors.fireEliteCore,
        _ => AppColors.fireCore,
      };

  Color badgeFill(BuildContext context, int count) =>
      glyphColor(context, count).withValues(alpha: AppOpacity.badgeFill);
}
