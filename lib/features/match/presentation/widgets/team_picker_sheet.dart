import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
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
    required this.competitionId,
  });

  final String title;
  final Color color;
  final List<Player> players;
  final Set<String> initiallySelected;
  final String competitionId;

  @override
  State<TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<TeamPickerSheet> {
  late final Set<String> _selected = Set.of(widget.initiallySelected);

  void _toggle(String playerId) {
    setState(() {
      if (!_selected.remove(playerId)) _selected.add(playerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: widget.title,
      titleColor: widget.color,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final player in _sortedByName(widget.players))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SelectableRow(
                label: player.displayName,
                color: widget.color,
                selected: _selected.contains(player.id),
                onTap: () => _toggle(player.id),
              ),
            ),
          AdaptiveButton(
            label: context.l10n.playersManageTitle,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () async {
              await context.push(Routes.players(widget.competitionId));
              if (context.mounted) Navigator.of(context).pop(_selected);
            },
          ),
        ],
      ),
      primaryButton: AdaptiveButton(
        label: context.l10n.commonDone,
        onPressed: () => Navigator.of(context).pop(_selected),
      ),
    );
  }
}
