import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';
import 'adaptive_icon.dart';
import 'app_platform.dart';

class AdaptiveTabBarItem {
  const AdaptiveTabBarItem({required this.glyph, required this.label});
  final AdaptiveGlyph glyph;
  final String label;
}

class AdaptiveTabBarAction {
  const AdaptiveTabBarAction({
    required this.glyph,
    required this.label,
    required this.onPressed,
  });
  final AdaptiveGlyph glyph;
  final String label;
  final VoidCallback onPressed;
}

class AdaptiveBottomTabBar extends StatelessWidget {
  const AdaptiveBottomTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.action,
  });

  final List<AdaptiveTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final AdaptiveTabBarAction? action;

  @override
  Widget build(BuildContext context) {
    if (AdaptiveGlass.isEnabled(context)) return _glass(context);
    if (AppPlatform.useCupertino) return _cupertino();
    return _material();
  }

  Widget _glass(BuildContext context) {
    if (action == null) return _glassBar(context);
    return Stack(
      children: [
        Positioned.fill(child: _glassBar(context)),
        Positioned(
          right: AppGlass.barMargin,
          bottom: MediaQuery.paddingOf(context).bottom + AppGlass.barMargin,
          child: _glassAction(context, action!),
        ),
      ],
    );
  }

  Widget _glassBar(BuildContext context) {
    return LiquidGlassTabBar.withImpeller(
      items: [for (final item in items) _glassItem(item)],
      selectedIndex: selectedIndex,
      onChanged: onTap,
      style: AdaptiveGlass.styleOf(
        context,
        cornerRadius: AppGlass.barCornerRadius,
      ),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor: AdaptiveColors.accent(context),
        unselectedColor: AppColors.neutral,
        iconSize: AppGlass.barIconSize,
        labelFontSize: AppTypography.labelTinySize,
      ),
      width: _glassBarWidth(context),
      height: AppGlass.barHeight,
      alignment: _glassAlignment(),
      margin: _glassMargin(),
    );
  }

  LiquidGlassTabBarItem _glassItem(AdaptiveTabBarItem item) {
    return LiquidGlassTabBarItem(
      label: item.label,
      iconBuilder: (context, glyph) =>
          AdaptiveIcon(item.glyph, color: glyph.color, size: glyph.size),
    );
  }

  double _glassBarWidth(BuildContext context) {
    final available =
        MediaQuery.sizeOf(context).width -
        AppGlass.barMargin * 2 -
        _glassActionSpace;
    return math.max(0, math.min(available, AppGlass.barMaxWidth));
  }

  Alignment _glassAlignment() =>
      action == null ? Alignment.bottomCenter : Alignment.bottomLeft;

  EdgeInsets _glassMargin() {
    return action == null
        ? const EdgeInsets.only(bottom: AppGlass.barMargin)
        : const EdgeInsets.only(
            left: AppGlass.barMargin,
            bottom: AppGlass.barMargin,
          );
  }

  Widget _glassAction(BuildContext context, AdaptiveTabBarAction action) {
    return Semantics(
      button: true,
      label: action.label,
      child: LiquidGlassTabBarAction(
        size: AppGlass.barHeight,
        onTap: action.onPressed,
        child: AdaptiveIcon(
          action.glyph,
          color: AdaptiveColors.glassGlyph(context),
          size: AppGlass.barIconSize,
        ),
      ),
    );
  }

  double get _glassActionSpace =>
      action == null ? 0 : AppGlass.barHeight + AppSpacing.sm;

  Widget _cupertino() {
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: _tap,
      items: [
        for (final item in _itemsWithAction())
          BottomNavigationBarItem(
            icon: AdaptiveIcon(item.glyph),
            label: item.label,
          ),
      ],
    );
  }

  Widget _material() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: _tap,
      destinations: [
        for (final item in _itemsWithAction())
          NavigationDestination(
            icon: AdaptiveIcon(item.glyph),
            label: item.label,
          ),
      ],
    );
  }

  List<AdaptiveTabBarItem> _itemsWithAction() {
    if (action case final action?) {
      return [
        ...items,
        AdaptiveTabBarItem(glyph: action.glyph, label: action.label),
      ];
    }
    return items;
  }

  void _tap(int index) {
    if (index == items.length) {
      action?.onPressed();
      return;
    }
    onTap(index);
  }
}
