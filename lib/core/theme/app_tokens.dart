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
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}

abstract final class AppOpacity {
  static const double cardFillFaint = 0.06;
  static const double surfaceFill = 0.08;
  static const double accentFill = 0.10;
  static const double neutralSurfaceFill = 0.12;
  static const double selectedFill = 0.14;
  static const double tintedButtonFill = 0.15;
  static const double badgeFill = 0.16;
  static const double accentBorder = 0.25;
  static const double controlBorder = 0.35;
  static const double fieldBorder = 0.4;
  static const double winnerBorder = 0.6;
}

abstract final class AppColors {
  static const Color seed = Color(0xFFBC4D08);
  static const Color seedOnDark = Color(0xFFFFB694);
  static const Color positive = Color(0xFF12855F);
  static const Color negative = Color(0xFFC0392B);
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFF8E97A6);
  static const Color teamA = seed;
  static const Color teamAOnDark = seedOnDark;
  static const Color teamB = Color(0xFF3566D8);
  static const Color teamBOnDark = Color(0xFFB4C7FF);

  static const Color gold = Color(0xFFD4A017);
  static const Color silver = Color(0xFF9AA0A6);
  static const Color bronze = Color(0xFFB07A46);

  static const Color fireCore = Color(0xFFFF6D00);
  static const Color iceCore = Color(0xFF29B6F6);

  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  static final Color neutralSurface = neutralSoft.withValues(
    alpha: AppOpacity.neutralSurfaceFill,
  );
  static final Color fireBadgeFill = fireCore.withValues(
    alpha: AppOpacity.badgeFill,
  );
}

abstract final class AppTypography {
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static const String brandFontFamily = 'Permanent Marker';

  static const double displaySize = 40;
  static const double headlineLargeSize = 28;
  static const double headlineMediumSize = 24;
  static const double titleLargeSize = 20;
  static const double titleMediumSize = 18;
  static const double titleSmallSize = 17;
  static const double bodyLargeSize = 16;
  static const double bodyMediumSize = 15;
  static const double bodySmallSize = 14;
  static const double labelLargeSize = 13;
  static const double captionSmallSize = 12;
  static const double labelTinySize = 11;

  static const TextStyle displayLarge = TextStyle(
    fontSize: displaySize,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: headlineLargeSize,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: headlineMediumSize,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: titleLargeSize,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: titleMediumSize,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: titleSmallSize,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: bodyLargeSize,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: bodyMediumSize,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: bodySmallSize,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: labelLargeSize,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: bodyMediumSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
  static const TextStyle caption = TextStyle(
    fontSize: labelLargeSize,
    color: AppColors.neutral,
  );
  static const TextStyle captionSmall = TextStyle(
    fontSize: captionSmallSize,
    color: AppColors.neutral,
  );
  static const TextStyle labelTiny = TextStyle(
    fontSize: labelTinySize,
    color: AppColors.neutral,
  );
}

const double kContentMaxWidth = 640;
