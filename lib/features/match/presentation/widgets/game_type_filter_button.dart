import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/game_type.enum.dart';
import '../pages/game_type_filter_sheet.dart';
import 'game_type_filter_option.enum.dart';

class GameTypeFilterButton extends StatelessWidget {
  const GameTypeFilterButton({
    super.key,
    required this.selected,
    required this.played,
    required this.onSelected,
  });

  final GameType? selected;
  final Set<GameType> played;
  final ValueChanged<GameType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBarAction(
      glyph: AdaptiveGlyph.filter,
      semanticLabel: context.l10n.gameTypeFilterPick,
      active: selected != null,
      onPressed: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final option = await showAdaptiveSheet<GameTypeFilterOption>(
      context,
      builder: (_) => GameTypeFilterSheet(
        selected: GameTypeFilterOption.from(selected),
        options: _options(),
      ),
    );
    if (option != null) onSelected(option.gameType);
  }

  List<GameTypeFilterOption> _options() {
    return [
      GameTypeFilterOption.all,
      for (final option in GameTypeFilterOption.values)
        if (option.gameType case final gameType?)
          if (played.contains(gameType) || gameType == selected) option,
    ];
  }
}
