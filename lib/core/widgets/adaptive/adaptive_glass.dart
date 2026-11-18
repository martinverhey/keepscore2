import 'package:flutter/widgets.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'app_platform.dart';

export 'package:liquid_glass_easy/liquid_glass_easy.dart'
    show
        LiquidGlassLens,
        LiquidGlassEdge,
        LiquidGlassFlex,
        LiquidGlassScrollEdge,
        LiquidGlassSheet,
        LiquidGlassShape,
        LiquidGlassStyle,
        LiquidGlassSwitch,
        LiquidGlassTabBar,
        LiquidGlassTabBarAction,
        LiquidGlassTabBarItem,
        LiquidGlassTabItemStyle,
        LiquidGlassTouch;

class AdaptiveGlass extends StatelessWidget {
  static const Color _darkControlFill = Color(0x8C383838);
  static const Color _lightControlFill = Color(0x8CFFFFFF);
  static const double _controlHoldScale = 0.12;
  static const double _controlTapScale = 0.08;

  static const LiquidGlassTouch controlTouch = LiquidGlassTouch.flexing(
    LiquidGlassFlex(holdScale: _controlHoldScale, tapScale: _controlTapScale),
  );

  static final LiquidGlassStyle _darkControlStyle = LiquidGlassTabBar
      .defaultDarkStyle
      .copyWith(color: _darkControlFill);
  static final LiquidGlassStyle _lightControlStyle = LiquidGlassTabBar
      .defaultStyle
      .copyWith(color: _lightControlFill);

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

  static LiquidGlassStyle controlStyleOf(BuildContext context) {
    return brightnessOf(context) == Brightness.dark
        ? _darkControlStyle
        : _lightControlStyle;
  }

  static LiquidGlassStyle groupedBarActionStyleOf(BuildContext context) {
    return controlStyleOf(context).copyWith(
      shape: const LiquidGlassShape(cornerRadius: AppGlass.barActionSize / 2),
    );
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
