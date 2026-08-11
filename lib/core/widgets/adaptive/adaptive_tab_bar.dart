import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  });

  final List<AdaptiveTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.useCupertino) {
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
