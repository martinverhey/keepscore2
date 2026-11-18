import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_tokens.dart';
import 'app_platform.dart';

abstract final class AdaptiveColors {
  static Color accent(BuildContext context) =>
      _forBrightness(context, AppColors.seed, AppColors.seedOnDark);

  static Color teamA(BuildContext context) =>
      _forBrightness(context, AppColors.teamA, AppColors.teamAOnDark);

  static Color teamB(BuildContext context) =>
      _forBrightness(context, AppColors.teamB, AppColors.teamBOnDark);

  static Color iceElite(BuildContext context) => _forBrightness(
    context,
    AppColors.iceEliteCore,
    AppColors.iceEliteCoreOnDark,
  );

  static Color modalSurface(BuildContext context) => _forBrightness(
    context,
    AppColors.modalSurface,
    AppColors.modalSurfaceOnDark,
  );

  static Color glassSheetTint(BuildContext context) =>
      modalSurface(context).withValues(alpha: AppOpacity.glassSheetFill);

  static bool isDark(BuildContext context) =>
      _forBrightness(context, AppColors.white, AppColors.black) ==
      AppColors.black;

  static Color destructive(BuildContext context) => AppPlatform.useCupertino
      ? CupertinoDynamicColor.resolve(CupertinoColors.destructiveRed, context)
      : Theme.of(context).colorScheme.error;

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
