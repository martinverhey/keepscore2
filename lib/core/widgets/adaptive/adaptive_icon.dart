import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'adaptive_glyph.dart';
import 'app_platform.dart';

export 'adaptive_glyph.dart';

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
    AdaptiveGlyph.check => CupertinoIcons.checkmark,
    AdaptiveGlyph.invite => CupertinoIcons.share,
    AdaptiveGlyph.star => CupertinoIcons.star_fill,
    AdaptiveGlyph.add => CupertinoIcons.add,
    AdaptiveGlyph.medal => CupertinoIcons.rosette,
    AdaptiveGlyph.fire => CupertinoIcons.flame_fill,
    AdaptiveGlyph.ice => CupertinoIcons.snow,
  };

  IconData get _material => switch (glyph) {
    AdaptiveGlyph.leaderboard => Icons.leaderboard,
    AdaptiveGlyph.newMatch => Icons.add_circle,
    AdaptiveGlyph.matches => Icons.history,
    AdaptiveGlyph.settings => Icons.settings,
    AdaptiveGlyph.chevronRight => Icons.chevron_right,
    AdaptiveGlyph.check => Icons.check,
    AdaptiveGlyph.invite => Icons.ios_share,
    AdaptiveGlyph.star => Icons.star,
    AdaptiveGlyph.add => Icons.add,
    AdaptiveGlyph.medal => Icons.military_tech,
    AdaptiveGlyph.fire => Icons.local_fire_department,
    AdaptiveGlyph.ice => Icons.ac_unit,
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
    this.semanticLabel,
  });

  final AdaptiveGlyph glyph;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppPlatform.useCupertino
        ? Semantics(
            button: true,
            label: semanticLabel,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              child: AdaptiveIcon(glyph),
            ),
          )
        : IconButton(
            onPressed: onPressed,
            tooltip: semanticLabel,
            icon: AdaptiveIcon(glyph),
          );
  }
}
