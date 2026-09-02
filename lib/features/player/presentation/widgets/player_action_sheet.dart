import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../domain/player.model.dart';
import 'player_action.enum.dart';

class PlayerActionSheet extends StatelessWidget {
  const PlayerActionSheet({
    super.key,
    required this.player,
    required this.canRename,
    required this.canRemove,
  });
  final Player player;
  final bool canRename;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: player.displayName,
      content: _actions(context),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canRename) _renameButton(context),
        if (!player.isActive) ...[
          if (canRename) const SizedBox(height: AppSpacing.sm),
          _restoreButton(context),
        ] else if (canRemove) ...[
          if (canRename) const SizedBox(height: AppSpacing.sm),
          _removeButton(context),
        ],
      ],
    );
  }

  Widget _renameButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.playersRename,
      kind: AdaptiveButtonKind.tinted,
      onPressed: () => Navigator.of(context).pop(PlayerAction.rename),
    );
  }

  Widget _restoreButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.playersRestore,
      kind: AdaptiveButtonKind.tinted,
      onPressed: () => Navigator.of(context).pop(PlayerAction.restore),
    );
  }

  Widget _removeButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.playersRemove,
      kind: AdaptiveButtonKind.destructive,
      onPressed: () => Navigator.of(context).pop(PlayerAction.remove),
    );
  }
}
