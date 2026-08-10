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

  static Color _forBrightness(BuildContext context, Color light, Color dark) {
    final brightness = AppPlatform.useCupertino
        ? CupertinoTheme.brightnessOf(context)
        : Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
