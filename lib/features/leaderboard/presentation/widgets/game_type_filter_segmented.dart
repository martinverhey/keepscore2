import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../match/domain/game_type.dart';
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

class GameTypeFilterSegmented extends StatelessWidget {
  const GameTypeFilterSegmented({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GameType? selected;
  final ValueChanged<GameType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSegmented<GameTypeFilterOption>(
      segments: {
        for (final option in GameTypeFilterOption.values)
          option: option == GameTypeFilterOption.all
              ? context.l10n.leaderboardFilterAll
              : gameTypeLabel(context, option.gameType!),
      },
      value: GameTypeFilterOption.from(selected),
      onChanged: (option) => onSelected(option.gameType),
    );
  }
}
