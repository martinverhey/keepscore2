import 'package:flutter/widgets.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'app_platform.dart';

export 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show
        LiquidGlassLens,
        LiquidGlassEdge,
        LiquidGlassFab,
        LiquidGlassScrollEdge,
        LiquidGlassSheet,
        LiquidGlassShape,
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
    this.tint,
    this.opaqueFallback,
  });

  final Widget child;
  final Color? tint;
  final Widget? opaqueFallback;

  static Future<void> warmUp() {
    if (!AppPlatform.useLiquidGlass) return Future<void>.value();
    return LiquidGlassShaders.ensureLoaded();
  }

  static bool isEnabled(BuildContext context) =>
      AppPlatform.useLiquidGlass && !MediaQuery.highContrastOf(context);

  static LiquidGlassStyle groupedBarActionStyle() {
    return LiquidGlassTabBarAction.defaultStyle.copyWith(
      shape: const LiquidGlassShape(cornerRadius: AppGlass.barActionSize / 2),
    );
  }

  static LiquidGlassStyle tabBarStyleOf(BuildContext context) {
    return brightnessOf(context) == Brightness.dark
        ? LiquidGlassTabBar.defaultDarkStyle
        : LiquidGlassTabBar.defaultStyle;
  }

  static LiquidGlassTabItemStyle tabItemStyleOf(BuildContext context) {
    return LiquidGlassTabItemStyle(
      selectedColor: AdaptiveColors.accent(context),
    ).resolve(brightnessOf(context));
  }

  static Color glyphColorOf(BuildContext context, {bool active = false}) {
    return tabItemStyleOf(context).colorFor(selected: active);
  }

  static Brightness brightnessOf(BuildContext context) {
    return AdaptiveColors.isDark(context) ? Brightness.dark : Brightness.light;
  }

  @override
  Widget build(BuildContext context) {
    if (!isEnabled(context)) return opaqueFallback ?? child;
    return LiquidGlassLens(
      style: LiquidGlassSheet.defaultStyle.copyWith(
        shape: LiquidGlassSheet.defaultShape(),
        color: tint,
      ),
      child: child,
    );
  }
}
