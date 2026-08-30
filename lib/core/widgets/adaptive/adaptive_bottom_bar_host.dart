import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_floating_action.dart';
import 'adaptive_glass.dart';

class AdaptiveBottomBarAction {
  const AdaptiveBottomBarAction({
    required this.glyph,
    required this.label,
    required this.onPressed,
  });

  final AdaptiveGlyph glyph;
  final String label;
  final VoidCallback onPressed;
}

class AdaptiveBottomBarHost extends StatelessWidget {
  const AdaptiveBottomBarHost({
    super.key,
    required this.child,
    this.bar,
    this.action,
  });

  final Widget child;
  final Widget? bar;
  final AdaptiveBottomBarAction? action;

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
        if (action case final action?)
          Positioned(
            right: AppGlass.barMargin,
            bottom: MediaQuery.paddingOf(context).bottom + AppGlass.barMargin,
            child: _action(action),
          ),
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
    return Column(children: [Expanded(child: _floated()), bar!]);
  }

  Widget _floated() {
    if (action case final action?) {
      return Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _action(action),
          ),
        ],
      );
    }
    return child;
  }

  Widget _action(AdaptiveBottomBarAction action) {
    return AdaptiveFloatingAction(
      glyph: action.glyph,
      onPressed: action.onPressed,
      semanticLabel: action.label,
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
