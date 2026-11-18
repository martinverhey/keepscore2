import 'package:material_ui/material_ui.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_glass.dart';
import 'adaptive_icon.dart';
import 'grouped_bar_action_scope.dart';

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
    return AdaptiveIconButton(
      glyph: glyph,
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
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: _slot(context),
      ),
    );
  }

  Widget _slot(BuildContext context) {
    return SizedBox.square(
      dimension: AppGlass.barActionSize,
      child: Center(
        child: AdaptiveIcon(
          glyph,
          color: _glyphColor(context),
          size: AppGlass.barIconSize,
        ),
      ),
    );
  }

  Widget _lens(BuildContext context) {
    return LiquidGlassTabBarAction(
      onTap: onPressed,
      child: AdaptiveIcon(glyph, color: _glyphColor(context)),
    );
  }

  Color _glyphColor(BuildContext context) =>
      AdaptiveGlass.glyphColorOf(context, active: active);
}
