import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';

class AdaptiveBottomBarHost extends StatelessWidget {
  const AdaptiveBottomBarHost({super.key, required this.child, this.bar});

  final Widget child;
  final Widget? bar;

  static const double glassInset = AppGlass.barHeight + AppGlass.barMargin;

  static double insetOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_AdaptiveBottomBarInset>()
            ?.inset ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    if (bar == null) return child;
    return AdaptiveGlass.isEnabled(context)
        ? _floating(context)
        : _stacked(context);
  }

  Widget _floating(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _AdaptiveBottomBarInset(inset: glassInset, child: child),
        ),
        _scrollEdge(context),
        Positioned.fill(child: bar!),
      ],
    );
  }

  Widget _scrollEdge(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height:
          glassInset +
          MediaQuery.paddingOf(context).bottom +
          AppGlass.scrollEdgeFade,
      child: IgnorePointer(
        child: LiquidGlassScrollEdge(
          edge: LiquidGlassEdge.bottom,
          color: AdaptiveColors.scrollEdgeTint(context),
        ),
      ),
    );
  }

  Widget _stacked(BuildContext context) {
    return ColoredBox(
      color: AdaptiveColors.pageBackground(context),
      child: SafeArea(
        top: false,
        child: Column(children: [Expanded(child: child), bar!]),
      ),
    );
  }
}

class _AdaptiveBottomBarInset extends InheritedWidget {
  const _AdaptiveBottomBarInset({required this.inset, required super.child});

  final double inset;

  @override
  bool updateShouldNotify(_AdaptiveBottomBarInset oldWidget) =>
      inset != oldWidget.inset;
}
