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

class AdaptiveBottomTabBar extends StatelessWidget {
  const AdaptiveBottomTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.reservesTrailingAction = false,
  });

  final List<AdaptiveTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool reservesTrailingAction;

  @override
  Widget build(BuildContext context) {
    if (AdaptiveGlass.isEnabled(context)) return _glassBar(context);
    if (AppPlatform.useCupertino) return _cupertino();
    return _material();
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
      reservesTrailingAction ? Alignment.bottomLeft : Alignment.bottomCenter;

  EdgeInsets _glassMargin() {
    return reservesTrailingAction
        ? const EdgeInsets.only(
            left: AppGlass.barMargin,
            bottom: AppGlass.barMargin,
          )
        : const EdgeInsets.only(bottom: AppGlass.barMargin);
  }

  double get _glassActionSpace =>
      reservesTrailingAction ? AppGlass.barHeight + AppSpacing.sm : 0;

  Widget _cupertino() {
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: [
        for (final item in items)
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
      onDestinationSelected: onTap,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: AdaptiveIcon(item.glyph),
            label: item.label,
          ),
      ],
    );
  }
}
