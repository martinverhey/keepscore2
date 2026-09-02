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
  static const double shadow = 0.18;
  static const double glassFill = 0.22;
  static const double glassFillOnDark = 0.28;
  static const double scrollEdgeFill = 0.9;
  static const double glassSheetFill = 0.75;
  static const double glassRim = 0.7;
  static const double glassRimOnDark = 0.32;
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
  static const Color fireEliteCore = Color(0xFF9333EA);
  static const Color iceCore = Color(0xFF29B6F6);

  static const Color modalSurface = Color(0xFFFAFAFA);
  static const Color modalSurfaceOnDark = Color(0xFF1F2023);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  static const Color splashGradientStart = Color(0xFFFF9400);
  static const Color splashGradientEnd = Color(0xFFFF6900);

  static final Color neutralSurface = neutralSoft.withValues(
    alpha: AppOpacity.neutralSurfaceFill,
  );
  static final Color fireBadgeFill = fireCore.withValues(
    alpha: AppOpacity.badgeFill,
  );
  static final Color fireEliteBadgeFill = fireEliteCore.withValues(
    alpha: AppOpacity.badgeFill,
  );
  static final Color glassTint = white.withValues(alpha: AppOpacity.glassFill);
  static final Color glassTintOnDark = modalSurfaceOnDark.withValues(
    alpha: AppOpacity.glassFillOnDark,
  );
  static final Color glassRim = white.withValues(alpha: AppOpacity.glassRim);
  static final Color glassRimOnDark = white.withValues(
    alpha: AppOpacity.glassRimOnDark,
  );
}

abstract final class AppGlass {
  static const double cornerRadius = 28;
  static const double barHeight = 64;
  static const double barMaxWidth = 420;
  static const double barMargin = AppSpacing.md;
  static const double barCornerRadius = barHeight / 2;
  static const double barIconSize = 24;
  static const double barActionSize = 60;
  static const double topBarHeight = barActionSize;
  static const double topBarSubtitleHeight = 20;
  static const double topBarSubtitleRise = 16;
  static const double rimIntensity = 0.25;
  static const double rimIntensityOnDark = 0.1;
  static const double rimAmbient = 1;
  static const double rimAmbientOnDark = 0.35;
  static const double scrollEdgeFade = 0;
  static const double blurSigma = 5;
  static const double distortion = 0.13;
  static const double distortionWidth = 34;
}

abstract final class AppTypography {
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static const String brandFontFamily = 'Permanent Marker';

  static const double brandInitialSize = 125;
  static const double brandWordSize = 55;
  static const double brandBylineSize = 20;
  static const double brandLineHeight = 0.76;

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
  static const TextStyle barTitle = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: headlineLargeSize,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: headlineLargeSize,
    fontWeight: FontWeight.w400,
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
  );
  static const TextStyle caption = TextStyle(
    fontSize: labelLargeSize,
    color: AppColors.neutral,
  );
  static final TextStyle captionStrong = caption.copyWith(
    fontWeight: FontWeight.w700,
  );
  static const TextStyle captionSmall = TextStyle(
    fontSize: captionSmallSize,
    color: AppColors.neutral,
  );
  static const TextStyle labelTiny = TextStyle(
    fontSize: labelTinySize,
    color: AppColors.neutral,
  );
  static const TextStyle brandInitial = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: brandInitialSize,
    height: brandLineHeight,
    color: AppColors.white,
  );
  static const TextStyle brandWord = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: brandWordSize,
    height: brandLineHeight,
    color: AppColors.white,
  );
  static const TextStyle brandByline = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: brandBylineSize,
    color: AppColors.black,
  );
}

const double kContentMaxWidth = 640;
