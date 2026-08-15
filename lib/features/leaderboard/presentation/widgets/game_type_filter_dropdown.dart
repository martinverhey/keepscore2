import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/pill_dropdown.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../match/domain/game_type.enum.dart';
import '../../../profile/presentation/widgets/game_type_label.dart';

enum GameTypeFilterOption {
  all,
  oneVOne,
  twoVTwo,
  threeVThree,
  fourVFour,
  mixed;

  GameType? get gameType => switch (this) {
    GameTypeFilterOption.all => null,
    GameTypeFilterOption.oneVOne => GameType.oneVOne,
    GameTypeFilterOption.twoVTwo => GameType.twoVTwo,
    GameTypeFilterOption.threeVThree => GameType.threeVThree,
    GameTypeFilterOption.fourVFour => GameType.fourVFour,
    GameTypeFilterOption.mixed => GameType.mixed,
  };

  static GameTypeFilterOption from(GameType? gameType) => switch (gameType) {
    null => GameTypeFilterOption.all,
    GameType.oneVOne => GameTypeFilterOption.oneVOne,
    GameType.twoVTwo => GameTypeFilterOption.twoVTwo,
    GameType.threeVThree => GameTypeFilterOption.threeVThree,
    GameType.fourVFour => GameTypeFilterOption.fourVFour,
    GameType.mixed => GameTypeFilterOption.mixed,
  };
}

class GameTypeFilterDropdown extends StatelessWidget {
  const GameTypeFilterDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GameType? selected;
  final ValueChanged<GameType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = selected == null
        ? context.l10n.leaderboardFilterAll
        : gameTypeLabel(context, selected!);

    return PillDropdown(label: label, onTap: () => _pick(context));
  }

  Future<void> _pick(BuildContext context) async {
    final option = await showAdaptiveSheet<GameTypeFilterOption>(
      context,
      builder: (_) =>
          GameTypeFilterSheet(selected: GameTypeFilterOption.from(selected)),
    );
    if (option != null) onSelected(option.gameType);
  }
}

class GameTypeFilterSheet extends StatelessWidget {
  const GameTypeFilterSheet({super.key, required this.selected});

  final GameTypeFilterOption selected;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.gameTypeFilterPick,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in GameTypeFilterOption.values)
            AdaptiveButton(
              label: option == GameTypeFilterOption.all
                  ? context.l10n.leaderboardFilterAll
                  : gameTypeLabel(context, option.gameType!),
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
