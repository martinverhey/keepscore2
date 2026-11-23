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
      child: Semantics(
        selected: isMe,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: _fill(context),
          ),
          child: Row(
            children: [
              Expanded(child: _nameRow(context)),
              if (_menuItems(context) case final items when items.isNotEmpty)
                AdaptiveMenuButton(
                  semanticLabel: context.l10n.commonMoreActions,
                  items: items,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _fill(BuildContext context) {
    if (!isMe) return AppColors.neutralSurface;
    return AdaptiveColors.accent(
      context,
    ).withValues(alpha: AppOpacity.selectedFill);
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

  bool get _showsRestore => !player.isActive && (canRename || canRemove);

  List<AdaptiveMenuItem> _menuItems(BuildContext context) {
    return [
      if (canRename)
        AdaptiveMenuItem(
          label: context.l10n.playersRename,
          glyph: AdaptiveGlyph.edit,
          onSelected: () => _rename(context),
        ),
      if (_showsRestore)
        AdaptiveMenuItem(
          label: context.l10n.playersRestore,
          glyph: AdaptiveGlyph.restore,
          onSelected: () => _restore(context),
        )
      else if (canRemove)
        AdaptiveMenuItem(
          label: context.l10n.playersRemove,
          glyph: AdaptiveGlyph.delete,
          destructive: true,
          onSelected: () => _remove(context),
        ),
    ];
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
