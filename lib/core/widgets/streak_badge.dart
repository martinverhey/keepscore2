import 'package:flutter/widgets.dart';

import '../../features/profile/domain/streak_type.enum.dart';
import '../extensions/build_context.extension.dart';
import '../extensions/streak_type.extension.dart';
import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class StreakBadge extends StatelessWidget {
  static const _overlappedGlyphWidth = 0.85;

  const StreakBadge({
    super.key,
    required this.type,
    required this.count,
  });

  final StreakType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: type == StreakType.loss
          ? context.l10n.profileStreakLoss(count)
          : context.l10n.profileStreakWin(count),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            color: type.badgeFill(context, count),
          ),
          child: _glyphs(context),
        ),
      ),
    );
  }

  Widget _glyphs(BuildContext context) {
    final glyphCount = type.glyphCount(count);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < glyphCount; i++)
          i < glyphCount - 1 ? _overlapped(_glyph(context)) : _glyph(context),
      ],
    );
  }

  Widget _overlapped(Widget glyph) {
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: _overlappedGlyphWidth,
      child: glyph,
    );
  }

  Widget _glyph(BuildContext context) {
    return AdaptiveIcon(
      type.glyph,
      color: type.glyphColor(context, count),
      size: 13,
    );
  }
}
