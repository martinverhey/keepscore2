import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'app_platform.dart';

abstract final class AdaptiveColors {
  static Color accent(BuildContext context) =>
      _forBrightness(context, AppColors.seed, AppColors.seedOnDark);

  static Color teamA(BuildContext context) =>
      _forBrightness(context, AppColors.teamA, AppColors.teamAOnDark);

  static Color teamB(BuildContext context) =>
      _forBrightness(context, AppColors.teamB, AppColors.teamBOnDark);

  static Color modalSurface(BuildContext context) => _forBrightness(
    context,
    AppColors.modalSurface,
    AppColors.modalSurfaceOnDark,
  );

  static Color glassTint(BuildContext context) => _forBrightness(
    context,
    AppColors.glassTint,
    AppColors.glassTintOnDark,
  );

  static Color glassSheetTint(BuildContext context) =>
      modalSurface(context).withValues(alpha: AppOpacity.glassSheetFill);

  static Color scrollEdgeTint(BuildContext context) =>
      pageBackground(context).withValues(alpha: AppOpacity.scrollEdgeFill);

  static Color glassGlyph(BuildContext context) =>
      _forBrightness(context, AppColors.black, AppColors.white);

  static Color pageBackground(BuildContext context) => AppPlatform.useCupertino
      ? CupertinoTheme.of(context).scaffoldBackgroundColor
      : Theme.of(context).scaffoldBackgroundColor;

  static Color surfaceTint(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  static Color divider(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color _forBrightness(BuildContext context, Color light, Color dark) {
    final brightness = AppPlatform.useCupertino
        ? CupertinoTheme.brightnessOf(context)
        : Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
