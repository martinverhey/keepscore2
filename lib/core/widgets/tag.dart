import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

enum TagStyle { pill, code }

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
    final isCode = style == TagStyle.code;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: isCode ? AppSpacing.xs : 2,
      ),
      decoration: BoxDecoration(
        borderRadius: isCode
            ? BorderRadius.circular(AppRadius.sm)
            : AppRadius.pill,
        color: color.withValues(alpha: isCode ? 0.14 : 0.16),
      ),
      child: Text(
        label,
        style: (isCode ? AppTypography.labelLarge : AppTypography.labelTiny)
            .copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: isCode ? 1.2 : null,
              fontFeatures: isCode ? AppTypography.tabularFigures : null,
            ),
      ),
    );
  }
}
