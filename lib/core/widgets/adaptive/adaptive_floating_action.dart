import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';
import 'adaptive_icon.dart';
import 'adaptive_loader.dart';
import 'app_platform.dart';

export 'adaptive_glyph.enum.dart';

class AdaptiveFloatingAction extends StatelessWidget {
  const AdaptiveFloatingAction({
    super.key,
    required this.glyph,
    required this.onPressed,
    required this.semanticLabel,
    this.busy = false,
  });

  final AdaptiveGlyph glyph;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final bool busy;

  static const double diameter = 56;

  @override
  Widget build(BuildContext context) {
    if (AdaptiveGlass.isEnabled(context)) return _glass(context);
    return AppPlatform.useCupertino ? _cupertino(context) : _material(context);
  }

  Widget _glass(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: LiquidGlassTabBarAction(
        onTap: busy ? null : onPressed,
        size: AppGlass.barHeight,
        style: LiquidGlassTabBarAction.defaultStyle.copyWith(
          shape: AdaptiveGlass.shapeOf(
            context,
            cornerRadius: AppGlass.barHeight / 2,
          ),
        ),
        child: _child(AdaptiveColors.glassGlyph(context)),
      ),
    );
  }

  Widget _cupertino(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: busy ? null : onPressed,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: AdaptiveColors.accent(context),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: AppOpacity.shadow),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: _child(AppColors.white)),
        ),
      ),
    );
  }

  Widget _material(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      onPressed: busy ? null : onPressed,
      tooltip: semanticLabel,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      child: _child(scheme.onPrimary),
    );
  }

  Widget _child(Color foreground) {
    return busy
        ? AdaptiveLoader(size: 20, color: foreground)
        : AdaptiveIcon(glyph, color: foreground);
  }
}
