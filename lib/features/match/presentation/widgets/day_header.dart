import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import 'match_day_label.dart';

class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(
        matchDayLabel(context, day),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral,
        ),
      ),
    );
  }
}
