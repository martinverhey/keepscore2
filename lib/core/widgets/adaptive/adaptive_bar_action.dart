import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';
import 'adaptive_icon.dart';

export 'adaptive_glyph.enum.dart';

class AdaptiveBarAction extends StatelessWidget {
  const AdaptiveBarAction({
    super.key,
    required this.glyph,
    required this.onPressed,
    this.semanticLabel,
    this.active = false,
  });

  final AdaptiveGlyph glyph;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!AdaptiveGlass.isEnabled(context)) {
      return AdaptiveIconButton(
        glyph: glyph,
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        active: active,
      );
    }
    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      child: LiquidGlassTabBarAction(
        onTap: onPressed,
        size: AppGlass.barActionSize,
        style: LiquidGlassTabBarAction.defaultStyle.copyWith(
          shape: AdaptiveGlass.shapeOf(
            context,
            cornerRadius: AppGlass.barActionSize / 2,
          ),
        ),
        child: AdaptiveIcon(glyph, color: _glyphColor(context)),
      ),
    );
  }

  Color _glyphColor(BuildContext context) => active
      ? AdaptiveColors.accent(context)
      : AdaptiveColors.glassGlyph(context);
}
