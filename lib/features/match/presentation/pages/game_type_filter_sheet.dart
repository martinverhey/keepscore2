import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/game_type.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../widgets/game_type_filter_option.enum.dart';

class GameTypeFilterSheet extends StatelessWidget {
  const GameTypeFilterSheet({
    super.key,
    required this.selected,
    required this.options,
  });

  final GameTypeFilterOption selected;
  final List<GameTypeFilterOption> options;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.gameTypeFilterPick,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in options)
            AdaptiveButton(
              label: option == GameTypeFilterOption.all
                  ? context.l10n.leaderboardFilterAll
                  : option.gameType!.label(context),
              kind: option == selected
                  ? AdaptiveButtonKind.tinted
                  : AdaptiveButtonKind.plain,
              onPressed: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
