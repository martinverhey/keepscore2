import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import '../../domain/player.model.dart';
import 'player_action.enum.dart';

class PlayerActionSheet extends StatelessWidget {
  const PlayerActionSheet({
    super.key,
    required this.player,
    required this.canRemove,
  });
  final Player player;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: player.displayName,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveButton(
            label: context.l10n.playersRename,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () => Navigator.of(context).pop(PlayerAction.rename),
          ),

          if (!player.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: context.l10n.playersRestore,
              kind: AdaptiveButtonKind.tinted,
              onPressed: () => Navigator.of(context).pop(PlayerAction.restore),
            ),
          ] else if (canRemove) ...[
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: context.l10n.playersRemove,
              kind: AdaptiveButtonKind.destructive,
              onPressed: () => Navigator.of(context).pop(PlayerAction.remove),
            ),
          ],
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
