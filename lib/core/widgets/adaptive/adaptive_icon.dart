import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'adaptive_colors.dart';
import 'adaptive_glyph.enum.dart';
import 'app_platform.dart';

export 'adaptive_glyph.enum.dart';

class AdaptiveIcon extends StatelessWidget {
  const AdaptiveIcon(this.glyph, {super.key, this.color, this.size});

  final AdaptiveGlyph glyph;
  final Color? color;
  final double? size;

  IconData get _cupertino => switch (glyph) {
    AdaptiveGlyph.leaderboard => CupertinoIcons.chart_bar_alt_fill,
    AdaptiveGlyph.newMatch => CupertinoIcons.add_circled_solid,
    AdaptiveGlyph.matches => CupertinoIcons.list_bullet,
    AdaptiveGlyph.players => CupertinoIcons.person_2_fill,
    AdaptiveGlyph.history => CupertinoIcons.clock_fill,
    AdaptiveGlyph.settings => CupertinoIcons.gear,
    AdaptiveGlyph.more => CupertinoIcons.ellipsis,
    AdaptiveGlyph.filter => CupertinoIcons.line_horizontal_3_decrease,
    AdaptiveGlyph.competitions => CupertinoIcons.rectangle_stack_fill,
    AdaptiveGlyph.back => CupertinoIcons.chevron_back,
    AdaptiveGlyph.chevronRight => CupertinoIcons.chevron_right,
    AdaptiveGlyph.chevronDown => CupertinoIcons.chevron_down,
    AdaptiveGlyph.check => CupertinoIcons.checkmark,
    AdaptiveGlyph.invite => CupertinoIcons.share,
    AdaptiveGlyph.rename => CupertinoIcons.pencil,
    AdaptiveGlyph.delete => CupertinoIcons.delete,
    AdaptiveGlyph.restore => CupertinoIcons.arrow_up_bin,
    AdaptiveGlyph.leave => CupertinoIcons.square_arrow_right,
    AdaptiveGlyph.star => CupertinoIcons.star_fill,
    AdaptiveGlyph.add => CupertinoIcons.add,
    AdaptiveGlyph.medal => CupertinoIcons.rosette,
    AdaptiveGlyph.trophy => Icons.emoji_events,
    AdaptiveGlyph.fire => CupertinoIcons.flame_fill,
    AdaptiveGlyph.ice => CupertinoIcons.snow,
    AdaptiveGlyph.light => CupertinoIcons.sun_max_fill,
    AdaptiveGlyph.dark => CupertinoIcons.moon_fill,
  };

  IconData get _material => switch (glyph) {
    AdaptiveGlyph.leaderboard => Icons.leaderboard,
    AdaptiveGlyph.newMatch => Icons.add_circle,
    AdaptiveGlyph.matches => Icons.format_list_bulleted,
    AdaptiveGlyph.players => Icons.groups,
    AdaptiveGlyph.history => Icons.history,
    AdaptiveGlyph.settings => Icons.settings,
    AdaptiveGlyph.more => Icons.more_vert,
    AdaptiveGlyph.filter => Icons.filter_list,
    AdaptiveGlyph.competitions => Icons.layers,
    AdaptiveGlyph.back => Icons.arrow_back,
    AdaptiveGlyph.chevronRight => Icons.chevron_right,
    AdaptiveGlyph.chevronDown => Icons.keyboard_arrow_down,
    AdaptiveGlyph.check => Icons.check,
    AdaptiveGlyph.invite => Icons.ios_share,
    AdaptiveGlyph.rename => Icons.edit,
    AdaptiveGlyph.delete => Icons.delete,
    AdaptiveGlyph.restore => Icons.restore_from_trash,
    AdaptiveGlyph.leave => Icons.logout,
    AdaptiveGlyph.star => Icons.star,
    AdaptiveGlyph.add => Icons.add,
    AdaptiveGlyph.medal => Icons.military_tech,
    AdaptiveGlyph.trophy => Icons.emoji_events,
    AdaptiveGlyph.fire => Icons.local_fire_department,
    AdaptiveGlyph.ice => Icons.ac_unit,
    AdaptiveGlyph.light => Icons.light_mode,
    AdaptiveGlyph.dark => Icons.dark_mode,
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
    this.active = false,
    this.destructive = false,
    this.compact = false,
  });

  final AdaptiveGlyph glyph;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool active;
  final bool destructive;
  final bool compact;

  static const Size _compactSize = Size.square(32);

  @override
  Widget build(BuildContext context) {
    return AppPlatform.useCupertino
        ? Semantics(
            button: true,
            selected: active,
            label: semanticLabel,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: compact ? _compactSize : null,
              onPressed: onPressed,
              child: _icon(context),
            ),
          )
        : IconButton(
            onPressed: onPressed,
            tooltip: semanticLabel,
            isSelected: active,
            style: compact ? _compactStyle() : null,
            icon: _icon(context),
          );
  }

  ButtonStyle _compactStyle() {
    return IconButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: _compactSize,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _icon(BuildContext context) {
    return AdaptiveIcon(glyph, color: _color(context));
  }

  Color? _color(BuildContext context) {
    if (destructive) return AdaptiveColors.destructive(context);
    if (active) return AdaptiveColors.accent(context);
    return null;
  }
}
