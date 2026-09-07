import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/player.model.dart';
import '../cubit/players_cubit.dart';
import '../pages/player_name_sheet.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.player,
    required this.isOwnerRow,
    required this.isMe,
    required this.canRename,
    required this.canRemove,
  });

  final Player player;
  final bool isOwnerRow;
  final bool isMe;
  final bool canRename;
  final bool canRemove;

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
            Expanded(child: _identity(context)),
            if (_showsRestore)
              _restoreButton(context)
            else if (canRemove)
              _removeButton(context),
          ],
        ),
      ),
    );
  }

  Widget _identity(BuildContext context) {
    return Row(
      children: [
        Flexible(child: _nameRow(context)),
        if (canRename) _renameButton(context),
      ],
    );
  }

  Widget _nameRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          Tag(context.l10n.playersUnclaimed, color: AppColors.neutral),
        ],
      ],
    );
  }

  Color? _nameColor(BuildContext context) {
    if (!player.isActive) return AppColors.neutral;
    if (isMe) return AdaptiveColors.accent(context);
    return null;
  }

  Widget _renameButton(BuildContext context) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.rename,
      semanticLabel: context.l10n.playersRename,
      compact: true,
      onPressed: () => _rename(context),
    );
  }

  bool get _showsRestore => !player.isActive && (canRename || canRemove);

  Widget _restoreButton(BuildContext context) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.restore,
      semanticLabel: context.l10n.playersRestore,
      onPressed: () => _restore(context),
    );
  }

  Widget _removeButton(BuildContext context) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.delete,
      semanticLabel: context.l10n.playersRemove,
      destructive: true,
      onPressed: () => _remove(context),
    );
  }

  Future<void> _restore(BuildContext context) async {
    await context.read<PlayersCubit>().setActive(player.id, isActive: true);
  }

  Future<void> _rename(BuildContext context) async {
    final cubit = context.read<PlayersCubit>();

    final name = await showPlayerNameSheet(
      context,
      title: context.l10n.playersRenameTitle,
      submitLabel: context.l10n.commonSave,
      initialValue: player.displayName,
    );
    if (name == null || name == player.displayName) return;

    await cubit.rename(player.id, name);
  }

  Future<void> _remove(BuildContext context) async {
    final cubit = context.read<PlayersCubit>();

    final confirmed = await showAdaptiveConfirm(
      context,
      title: context.l10n.playersRemoveConfirmTitle(player.displayName),
      message: context.l10n.playersRemoveConfirmBody,
      confirmLabel: context.l10n.playersRemove,
      cancelLabel: context.l10n.commonCancel,
      destructive: true,
    );
    if (confirmed) await cubit.setActive(player.id, isActive: false);
  }
}
