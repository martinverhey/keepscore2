import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/player.model.dart';
import '../cubit/players_cubit.dart';
import 'player_action.enum.dart';
import 'player_action_sheet.dart';
import 'player_name_sheet.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.player,
    required this.isOwnerRow,
    required this.isMe,
    required this.canEdit,
  });

  final Player player;
  final bool isOwnerRow;
  final bool isMe;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: AppColors.neutralSurface,
        ),
        child: Row(
          children: [
            Expanded(child: _nameRow(context)),
            if (canEdit) _editButton(context),
          ],
        ),
      ),
    );
  }

  Widget _nameRow(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            player.displayName,
            style: AppTypography.bodyLarge.copyWith(color: _nameColor(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOwnerRow) ...[
          const SizedBox(width: AppSpacing.xs),
          Tag(context.l10n.playersOwner, color: AppColors.gold),
        ],
        if (player.isPlaceholder) ...[
          const SizedBox(width: AppSpacing.xs),
          Tag(context.l10n.playersDummy, color: AppColors.neutral),
        ],
      ],
    );
  }

  Color? _nameColor(BuildContext context) {
    if (!player.isActive) return AppColors.neutral;
    if (isMe) return AdaptiveColors.accent(context);
    return null;
  }

  Widget _editButton(BuildContext context) {
    return AdaptiveButton(
      label: context.l10n.playersEdit,
      kind: AdaptiveButtonKind.plain,
      expand: false,
      onPressed: () => _showActions(context),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final cubit = context.read<PlayersCubit>();

    final action = await showAdaptiveSheet<PlayerAction>(
      context,
      builder: (sheetContext) =>
          PlayerActionSheet(player: player, canRemove: !isMe),
    );
    if (action == null) return;

    switch (action) {
      case PlayerAction.rename:
        if (!context.mounted) return;
        final name = await showPlayerNameSheet(
          context,
          title: context.l10n.playersRenameTitle,
          submitLabel: context.l10n.commonSave,
          initialValue: player.displayName,
        );
        if (name != null && name != player.displayName) {
          await cubit.rename(player.id, name);
        }

      case PlayerAction.remove:
        if (!context.mounted) return;
        final confirmed = await showAdaptiveConfirm(
          context,
          title: context.l10n.playersRemoveConfirmTitle(player.displayName),
          message: context.l10n.playersRemoveConfirmBody,
          confirmLabel: context.l10n.playersRemove,
          cancelLabel: context.l10n.commonCancel,
          destructive: true,
        );
        if (confirmed) await cubit.setActive(player.id, isActive: false);

      case PlayerAction.restore:
        await cubit.setActive(player.id, isActive: true);
    }
  }
}
