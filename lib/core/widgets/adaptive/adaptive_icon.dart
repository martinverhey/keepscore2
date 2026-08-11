import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_platform.dart';

enum AdaptiveGlyph { leaderboard, newMatch, matches, settings, chevronRight }

class AdaptiveIcon extends StatelessWidget {
  const AdaptiveIcon(this.glyph, {super.key, this.color, this.size});

  final AdaptiveGlyph glyph;
  final Color? color;
  final double? size;

  IconData get _cupertino => switch (glyph) {
        AdaptiveGlyph.leaderboard => CupertinoIcons.chart_bar_alt_fill,
        AdaptiveGlyph.newMatch => CupertinoIcons.add_circled_solid,
        AdaptiveGlyph.matches => CupertinoIcons.clock,
        AdaptiveGlyph.settings => CupertinoIcons.gear,
        AdaptiveGlyph.chevronRight => CupertinoIcons.chevron_right,
      };

  IconData get _material => switch (glyph) {
        AdaptiveGlyph.leaderboard => Icons.leaderboard,
        AdaptiveGlyph.newMatch => Icons.add_circle,
        AdaptiveGlyph.matches => Icons.history,
        AdaptiveGlyph.settings => Icons.settings,
        AdaptiveGlyph.chevronRight => Icons.chevron_right,
      };

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppPlatform.useCupertino ? _cupertino : _material,
      color: color,
      size: size,
    );
  }
}

class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.glyph,
    required this.onPressed,
  });

  final AdaptiveGlyph glyph;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPlatform.useCupertino
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            child: AdaptiveIcon(glyph),
          )
        : IconButton(onPressed: onPressed, icon: AdaptiveIcon(glyph));
  }
}
