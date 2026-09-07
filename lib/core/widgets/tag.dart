import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

enum TagStyle { pill, code, codeLarge }

class Tag extends StatelessWidget {
  const Tag(
    this.label, {
    super.key,
    required this.color,
    this.style = TagStyle.pill,
  });

  final String label;
  final Color color;
  final TagStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: switch (style) {
          TagStyle.pill => 2,
          TagStyle.code => AppSpacing.xs,
          TagStyle.codeLarge => AppSpacing.sm,
        },
      ),
      decoration: BoxDecoration(
        borderRadius: style == TagStyle.pill
            ? AppRadius.pill
            : BorderRadius.circular(AppRadius.sm),
        color: color.withValues(
          alpha: style == TagStyle.pill
              ? AppOpacity.badgeFill
              : AppOpacity.selectedFill,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _labelStyle().copyWith(color: color),
      ),
    );
  }

  TextStyle _labelStyle() {
    return switch (style) {
      TagStyle.pill => AppTypography.labelTiny.copyWith(
        fontWeight: FontWeight.w700,
      ),
      TagStyle.code => AppTypography.labelLarge.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        fontFeatures: AppTypography.tabularFigures,
      ),
      TagStyle.codeLarge => AppTypography.headlineMedium.copyWith(
        letterSpacing: 3,
        fontFeatures: AppTypography.tabularFigures,
      ),
    };
  }
}
