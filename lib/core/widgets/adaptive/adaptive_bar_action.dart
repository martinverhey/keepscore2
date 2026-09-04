import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_button.dart';
import 'adaptive_colors.dart';
import 'adaptive_glass.dart';
import 'adaptive_icon.dart';
import 'grouped_bar_action_scope.dart';

export 'adaptive_glyph.enum.dart';

class AdaptiveBarAction extends StatelessWidget {
  const AdaptiveBarAction({
    super.key,
    this.glyph,
    this.label,
    required this.onPressed,
    this.semanticLabel,
    this.active = false,
  }) : assert(
         (glyph == null) != (label == null),
         'Pass either glyph or label, never both',
       );

  final AdaptiveGlyph? glyph;
  final String? label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!AdaptiveGlass.isEnabled(context)) return _platformButton(context);
    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      child: GroupedBarActionScope.of(context)
          ? _grouped(context)
          : _lens(context),
    );
  }

  Widget _platformButton(BuildContext context) {
    if (label case final label?) {
      return AdaptiveButton(
        label: label,
        kind: AdaptiveButtonKind.plain,
        expand: false,
        onPressed: onPressed,
      );
    }
    return AdaptiveIconButton(
      glyph: glyph!,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      active: active,
    );
  }

  Widget _grouped(BuildContext context) {
    final onTap = onPressed;
    if (onTap == null) return _slot(context);
    return Material(
      color: AppColors.transparent,
      shape: _inkShape(),
      child: InkWell(
        customBorder: _inkShape(),
        onTap: onTap,
        child: _slot(context),
      ),
    );
  }

  Widget _slot(BuildContext context) {
    if (label case final label?) return _labelSlot(context, label);
    return SizedBox.square(
      dimension: AppGlass.barActionSize,
      child: Center(
        child: AdaptiveIcon(
          glyph!,
          color: _glyphColor(context),
          size: AppGlass.barIconSize,
        ),
      ),
    );
  }

  Widget _labelSlot(BuildContext context, String label) {
    return SizedBox(
      height: AppGlass.barActionSize,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              color: _glyphColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lens(BuildContext context) {
    if (label != null) {
      return LiquidGlassLens(
        style: AdaptiveGlass.barActionStyle(context),
        child: _grouped(context),
      );
    }
    return LiquidGlassTabBarAction(
      onTap: onPressed,
      size: AppGlass.barActionSize,
      style: AdaptiveGlass.barActionStyle(context),
      child: AdaptiveIcon(glyph!, color: _glyphColor(context)),
    );
  }

  ShapeBorder _inkShape() =>
      label == null ? const CircleBorder() : const StadiumBorder();

  Color _glyphColor(BuildContext context) => active
      ? AdaptiveColors.accent(context)
      : AdaptiveColors.glassGlyph(context);
}
