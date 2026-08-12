import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../match/domain/game_type.dart';
import '../../../profile/presentation/widgets/game_type_label.dart';

class GameTypeFilterBar extends StatelessWidget {
  const GameTypeFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GameType? selected;
  final ValueChanged<GameType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final gameType in [null, ...GameType.values]) ...[
            if (gameType != null) const SizedBox(width: AppSpacing.xs),
            AdaptiveButton(
              label: gameType == null
                  ? context.l10n.leaderboardFilterAll
                  : gameTypeLabel(context, gameType),
              kind: gameType == selected
                  ? AdaptiveButtonKind.tinted
                  : AdaptiveButtonKind.plain,
              expand: false,
              onPressed: () => onSelected(gameType),
            ),
          ],
        ],
      ),
    );
  }
}
