import 'package:flutter/widgets.dart';

import '../../features/profile/domain/streak_type.enum.dart';
import '../extensions/build_context.extension.dart';
import 'streak_badge.dart';

class StackedStreakBadge extends StatelessWidget {
  static const _pillGap = 2.0;

  const StackedStreakBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${context.l10n.profileStreakWin(count)}, '
          '${context.l10n.profileStreakLoss(count)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreakBadge(type: StreakType.win, count: count),
            const SizedBox(height: _pillGap),
            StreakBadge(type: StreakType.loss, count: count),
          ],
        ),
      ),
    );
  }
}
