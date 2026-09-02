import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/selectable_row.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../player/domain/player.model.dart';

List<Player> _sortedByName(List<Player> players) {
  final sorted = List<Player>.of(players);
  sorted.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return sorted;
}

class TeamPickerSheet extends StatefulWidget {
  const TeamPickerSheet({
    super.key,
    required this.title,
    required this.color,
    required this.players,
    required this.initiallySelected,
    required this.onManagePlayers,
    required this.canManagePlayers,
    this.myPlayerId,
  });

  final String title;
  final Color color;
  final List<Player> players;
  final Set<String> initiallySelected;
  final Future<List<Player>> Function() onManagePlayers;
  final bool canManagePlayers;
  final String? myPlayerId;

  @override
  State<TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<TeamPickerSheet> {
  late final Set<String> _selected = Set.of(widget.initiallySelected);
  late List<Player> _players = widget.players;

  void _toggle(String playerId) {
    setState(() {
      if (!_selected.remove(playerId)) _selected.add(playerId);
    });
  }

  Future<void> _managePlayers() async {
    final players = await widget.onManagePlayers();
    if (!mounted) return;
    setState(() {
      _players = players;
      _selected.removeWhere(
        (playerId) => !players.any((player) => player.id == playerId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Set<String>>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_selected);
      },
      child: Sheet(
        title: widget.title,
        titleColor: widget.color,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final player in _sortedByName(_players))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SelectableRow(
                  label: player.displayName,
                  color: widget.color,
                  selected: _selected.contains(player.id),
                  onTap: () => _toggle(player.id),
                  labelColor: player.id == widget.myPlayerId
                      ? AdaptiveColors.accent(context)
                      : null,
                ),
              ),
            if (widget.canManagePlayers)
              AdaptiveButton(
                label: context.l10n.playersManageTitle,
                kind: AdaptiveButtonKind.tinted,
                onPressed: _managePlayers,
              ),
          ],
        ),
        primaryButton: AdaptiveButton(
          label: context.l10n.commonDone,
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ),
    );
  }
}
