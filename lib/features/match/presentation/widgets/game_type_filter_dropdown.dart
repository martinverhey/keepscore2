import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/game_type.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/pill_dropdown.dart';
import '../../../../core/widgets/sheet.dart';
import '../../domain/game_type.enum.dart';

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
    if (AdaptiveGlass.isEnabled(context)) {
      return AdaptiveBarAction(
        glyph: AdaptiveGlyph.filter,
        semanticLabel: context.l10n.gameTypeFilterPick,
        onPressed: () => _pick(context),
      );
    }
    return PillDropdown(label: _label(context), onTap: () => _pick(context));
  }

  String _label(BuildContext context) => selected == null
      ? context.l10n.leaderboardFilterAll
      : selected!.label(context);

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
