import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_tokens.dart';
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
    return LiquidGlassTabBar(
      items: [for (final item in items) _glassItem(item)],
      selectedIndex: selectedIndex,
      onChanged: onTap,
      style: AdaptiveGlass.tabBarStyleOf(context),
      itemStyle: AdaptiveGlass.tabItemStyleOf(context),
      width: _glassBarWidth(context),
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
    final content =
        AppGlass.barItemPadding * 2 + items.length * _glassTabWidth(context);
    final available =
        MediaQuery.sizeOf(context).width -
        AppGlass.barEdgeInset * 2 -
        _glassActionSpace;
    return math.max(0, math.min(content, available));
  }

  double _glassTabWidth(BuildContext context) {
    final widestLabel = items
        .map((item) => _labelWidth(context, item.label))
        .fold(0.0, math.max);
    return math.max(
      AppGlass.barTabMinWidth,
      widestLabel + AppGlass.barTabLabelInset,
    );
  }

  double _labelWidth(BuildContext context, String label) {
    final itemStyle = AdaptiveGlass.tabItemStyleOf(context);
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.copyWith(
          fontSize: itemStyle.labelFontSize,
          fontWeight: itemStyle.selectedFontWeight,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  Alignment _glassAlignment() =>
      reservesTrailingAction ? Alignment.bottomLeft : Alignment.bottomCenter;

  EdgeInsets _glassMargin() {
    return reservesTrailingAction
        ? const EdgeInsets.only(
            left: AppGlass.barEdgeInset,
            bottom: AppGlass.barEdgeInset,
          )
        : const EdgeInsets.only(bottom: AppGlass.barEdgeInset);
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
