import 'package:flutter/widgets.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'app_platform.dart';

export 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show
        LiquidGlassAppearance,
        LiquidGlassBlur,
        LiquidGlassLens,
        LiquidGlassRefraction,
        LiquidGlassEdge,
        LiquidGlassScrollEdge,
        LiquidGlassShape,
        OpticalBorder,
        LiquidGlassStyle,
        LiquidGlassSwitch,
        LiquidGlassTabBar,
        LiquidGlassTabBarAction,
        LiquidGlassTabBarItem,
        LiquidGlassTabItemStyle;

class AdaptiveGlass extends StatelessWidget {
  const AdaptiveGlass({
    super.key,
    required this.child,
    this.cornerRadius = AppGlass.cornerRadius,
    this.tint,
    this.opaqueFallback,
  });

  final Widget child;
  final double cornerRadius;
  final Color? tint;
  final Widget? opaqueFallback;

  static Future<void> warmUp() {
    if (!AppPlatform.useLiquidGlass) return Future<void>.value();
    return LiquidGlassShaders.ensureLoaded();
  }

  static bool isEnabled(BuildContext context) =>
      AppPlatform.useLiquidGlass && !MediaQuery.highContrastOf(context);

  static LiquidGlassShape shapeOf(
    BuildContext context, {
    double cornerRadius = AppGlass.cornerRadius,
  }) {
    final dark = AdaptiveColors.isDark(context);
    return LiquidGlassShape(
      cornerRadius: cornerRadius,
      lightColor: AdaptiveColors.glassRim(context),
      lightIntensity: dark
          ? AppGlass.rimIntensityOnDark
          : AppGlass.rimIntensity,
      borderType: OpticalBorder(
        ambientIntensity: dark
            ? AppGlass.rimAmbientOnDark
            : AppGlass.rimAmbient,
      ),
    );
  }

  static LiquidGlassStyle styleOf(
    BuildContext context, {
    double cornerRadius = AppGlass.cornerRadius,
    Color? tint,
  }) {
    return LiquidGlassStyle(
      shape: shapeOf(context, cornerRadius: cornerRadius),
      appearance: LiquidGlassAppearance(
        color: tint ?? AdaptiveColors.glassTint(context),
        blur: const LiquidGlassBlur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
      ),
      refraction: const LiquidGlassRefraction(
        distortion: AppGlass.distortion,
        distortionWidth: AppGlass.distortionWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isEnabled(context)) return opaqueFallback ?? child;
    return LiquidGlassLens(
      style: styleOf(context, cornerRadius: cornerRadius, tint: tint),
      child: child,
    );
  }
}
