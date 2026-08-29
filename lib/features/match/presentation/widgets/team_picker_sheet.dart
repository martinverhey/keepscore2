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
    this.myPlayerId,
  });

  final String title;
  final Color color;
  final List<Player> players;
  final Set<String> initiallySelected;
  final String competitionId;
  final String? myPlayerId;

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
            for (final player in _sortedByName(widget.players))
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
            AdaptiveButton(
              label: context.l10n.playersManageTitle,
              kind: AdaptiveButtonKind.tinted,
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop(_selected);
                router.push(Routes.players(widget.competitionId));
              },
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
