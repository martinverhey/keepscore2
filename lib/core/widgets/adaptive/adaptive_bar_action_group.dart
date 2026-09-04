import 'package:flutter/widgets.dart';

import '../../theme/app_tokens.dart';
import 'adaptive_bar_action.dart';
import 'adaptive_glass.dart';
import 'grouped_bar_action_scope.dart';

class AdaptiveBarActionGroup extends StatelessWidget {
  const AdaptiveBarActionGroup({super.key, required this.actions});

  static const int _minGrouped = 2;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.length < _minGrouped ||
        actions.any(_isLabelled) ||
        !AdaptiveGlass.isEnabled(context)) {
      return _row();
    }
    return LiquidGlassLens(
      style: AdaptiveGlass.barActionStyle(context),
      child: GroupedBarActionScope(child: _row()),
    );
  }

  Widget _row() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: actions,
    );
  }
}

bool _isLabelled(Widget action) =>
    action is AdaptiveBarAction && action.label != null;
