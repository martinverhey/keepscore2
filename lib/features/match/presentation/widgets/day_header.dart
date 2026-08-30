import 'package:flutter/widgets.dart';

import '../../../../core/extensions/date_time.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AdaptiveColors.pageBackground(context),
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          day.matchDayLabel(context),
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.neutral,
          ),
        ),
      ),
    );
  }
}
