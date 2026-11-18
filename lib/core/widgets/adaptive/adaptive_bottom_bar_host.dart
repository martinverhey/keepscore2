import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_floating_action.dart';
import 'adaptive_glass.dart';
import 'adaptive_icon.dart';

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

  static const double glassBarTop = AppGlass.barEdgeInset + AppGlass.barHeight;

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
          child: _AdaptiveBottomBarInset(
            inset: _glassInset(context),
            child: child,
          ),
        ),
        _scrollEdge(context),
        Positioned.fill(child: _bar(context, removeBottom: true)),
        if (action case final action?)
          Positioned(
            right: AppGlass.barEdgeInset,
            bottom: AppGlass.barEdgeInset,
            child: _glassAction(context, action),
          ),
      ],
    );
  }

  Widget _scrollEdge(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: glassBarTop + AppGlass.scrollEdgeFade,
      child: IgnorePointer(
        child: LiquidGlassScrollEdge(edge: LiquidGlassEdge.bottom),
      ),
    );
  }

  double _glassInset(BuildContext context) {
    return math.max(0, glassBarTop - MediaQuery.paddingOf(context).bottom);
  }

  Widget _stacked(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: _floated(),
          ),
        ),
        _bar(context),
      ],
    );
  }

  Widget _bar(BuildContext context, {bool removeBottom = false}) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: removeBottom,
      child: bar!,
    );
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

  Widget _glassAction(BuildContext context, AdaptiveBottomBarAction action) {
    return Semantics(
      button: true,
      label: action.label,
      child: LiquidGlassTabBarAction(
        onTap: action.onPressed,
        size: AppGlass.barHeight,
        child: AdaptiveIcon(
          action.glyph,
          color: AdaptiveGlass.glyphColorOf(context),
        ),
      ),
    );
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
