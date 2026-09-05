import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/selectable_row.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../player/domain/player.model.dart';
import '../../domain/match_entry.model.dart';
import '../widgets/team_picker_result.model.dart';

export '../widgets/team_picker_result.model.dart';

class TeamPickerSheet extends StatefulWidget {
  const TeamPickerSheet({
    super.key,
    required this.titleA,
    required this.titleB,
    required this.players,
    required this.initialA,
    required this.initialB,
    required this.startSide,
    required this.singleSelect,
    required this.onManagePlayers,
    required this.canManagePlayers,
    this.myPlayerId,
  });

  final String titleA;
  final String titleB;
  final List<Player> players;
  final Set<String> initialA;
  final Set<String> initialB;
  final MatchTeam startSide;
  final bool singleSelect;
  final Future<List<Player>> Function() onManagePlayers;
  final bool canManagePlayers;
  final String? myPlayerId;

  @override
  State<TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<TeamPickerSheet> {
  late final Map<MatchTeam, Set<String>> _selected = {
    MatchTeam.a: Set.of(widget.initialA),
    MatchTeam.b: Set.of(widget.initialB),
  };
  late MatchTeam _side = widget.startSide;
  late List<Player> _players = widget.players;
  bool _forward = true;

  @override
  Widget build(BuildContext context) {
    return PopScope<TeamPickerResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_result(isComplete: false));
      },
      child: Sheet(
        title: _side == MatchTeam.a ? widget.titleA : widget.titleB,
        titleColor: _color(context, _side),
        content: _steps(context),
        primaryButton: _buttons(context),
      ),
    );
  }

  Widget _steps(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: _startAlignedStack,
        transitionBuilder: _slide,
        child: KeyedSubtree(
          key: ValueKey(_side),
          child: _playerList(context, _side),
        ),
      ),
    );
  }

  Widget _slide(Widget child, Animation<double> animation) {
    final key = child.key;
    final isIncoming = key is ValueKey<MatchTeam> && key.value == _side;
    final leaving = _forward ? -1.0 : 1.0;
    final entering = _forward ? 1.0 : -1.0;

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(isIncoming ? entering : leaving, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _playerList(BuildContext context, MatchTeam side) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final player in _sortedByName(_selectable(side)))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SelectableRow(
              label: player.displayName,
              color: _color(context, side),
              selected: _selected[side]!.contains(player.id),
              onTap: () => _pick(side, player.id),
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
    );
  }

  Widget? _buttons(BuildContext context) {
    if (widget.singleSelect) {
      if (_side == MatchTeam.a) return null;
      return _previousButton(context);
    }
    if (_side == MatchTeam.a) return _nextButton(context);

    return Row(
      children: [
        Expanded(child: _previousButton(context)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _nextButton(context)),
      ],
    );
  }

  Widget _previousButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.commonPrevious,
      kind: AdaptiveButtonKind.tinted,
      onPressed: () => _goTo(MatchTeam.a),
    );
  }

  Widget _nextButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.commonNext,
      onPressed: _side == MatchTeam.a ? () => _goTo(MatchTeam.b) : _finish,
    );
  }

  List<Player> _selectable(MatchTeam side) {
    final taken = _selected[side.opposite]!;
    return _players
        .where((player) => !taken.contains(player.id))
        .toList(growable: false);
  }

  void _pick(MatchTeam side, String playerId) {
    final selection = _selected[side]!;
    if (!widget.singleSelect) {
      setState(() {
        if (!selection.remove(playerId)) selection.add(playerId);
      });
      return;
    }

    setState(() {
      selection
        ..clear()
        ..add(playerId);
    });
    if (side == MatchTeam.b) {
      _finish();
    } else {
      _goTo(MatchTeam.b);
    }
  }

  void _goTo(MatchTeam side) {
    setState(() {
      _forward = side == MatchTeam.b;
      _side = side;
    });
  }

  void _finish() => Navigator.of(context).pop(_result(isComplete: true));

  TeamPickerResult _result({required bool isComplete}) => TeamPickerResult(
    teamA: Set.of(_selected[MatchTeam.a]!),
    teamB: Set.of(_selected[MatchTeam.b]!),
    isComplete: isComplete,
  );

  Color _color(BuildContext context, MatchTeam side) => side == MatchTeam.a
      ? AdaptiveColors.teamA(context)
      : AdaptiveColors.teamB(context);

  Future<void> _managePlayers() async {
    final players = await widget.onManagePlayers();
    if (!mounted) return;
    setState(() {
      _players = players;
      for (final selection in _selected.values) {
        selection.removeWhere(
          (playerId) => !players.any((player) => player.id == playerId),
        );
      }
    });
  }
}

Widget _startAlignedStack(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    alignment: AlignmentDirectional.topStart,
    children: [...previousChildren, ?currentChild],
  );
}

List<Player> _sortedByName(List<Player> players) {
  final sorted = List<Player>.of(players);
  sorted.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return sorted;
}
