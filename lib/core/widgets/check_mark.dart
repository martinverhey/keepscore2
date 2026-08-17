import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive.dart';

class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : null,
        border: Border.all(
          color: selected
              ? color
              : AppColors.neutral.withValues(alpha: AppOpacity.controlBorder),
        ),
      ),
      child: selected
          ? const AdaptiveIcon(
              AdaptiveGlyph.check,
              color: AppColors.white,
              size: 14,
            )
          : null,
    );
  }
}
