import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(lg));
}

// The accent and the team colours carry a second value for dark surfaces.
// Reading them straight off a dark background leaves them at about 4:1, which
// is where a saturated mid-tone lands whatever its hue. Resolve them through
// `AdaptiveColors`, never directly.
abstract final class AppColors {
  static const Color seed = Color(0xFFBC4D08);
  static const Color seedOnDark = Color(0xFFFFB694);
  static const Color positive = Color(0xFF12855F);
  static const Color negative = Color(0xFFC0392B);
  static const Color neutral = Color(0xFF6B7280);
  static const Color teamA = seed;
  static const Color teamAOnDark = seedOnDark;
  static const Color teamB = Color(0xFF3566D8);
  static const Color teamBOnDark = Color(0xFFB4C7FF);

  static const Color gold = Color(0xFFD4A017);
  static const Color silver = Color(0xFF9AA0A6);
  static const Color bronze = Color(0xFFB07A46);
}

const double kContentMaxWidth = 640;
