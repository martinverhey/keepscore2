import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../domain/player.dart';
import '../cubit/players_cubit.dart';
import 'player_action.dart';
import 'player_name_sheet.dart';

export 'player_action.dart';

class Players extends StatelessWidget {
  const Players({
    super.key,
    required this.ownerUserId,
    required this.myUserId,
    required this.isRegistered,
  });

  final String? ownerUserId;
  final String? myUserId;
  final bool isRegistered;

  bool get _isOwner =>
      isRegistered && myUserId != null && myUserId == ownerUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PlayersCubit>();

    return BlocBuilder<PlayersCubit, PlayersState>(
      builder: (context, state) {
        if (state.status == PlayersStatus.loading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AdaptiveLoader(),
          );
        }

        if (state.status == PlayersStatus.failed && state.players.isEmpty) {
          return ErrorRetry(
            message: state.failure!.localized(l10n),
            retryLabel: l10n.commonRetry,
            onRetry: cubit.load,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.playersTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  l10n.competitionPlayers(state.active.length),
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (state.active.isEmpty)
              EmptyState(message: l10n.playersEmpty)
            else ...[
              for (final player in state.claimed)
                _PlayerRow(
                  player: player,
                  isOwnerRow:
                      player.userId != null && player.userId == ownerUserId,
                  isMe: player.userId != null && player.userId == myUserId,
                  canEdit: _canEdit(player),
                ),

              if (state.unclaimed.isNotEmpty) ...[
                if (state.claimed.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.playersUnclaimed,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final player in state.unclaimed)
                  _PlayerRow(
                    player: player,
                    isOwnerRow:
                        player.userId != null && player.userId == ownerUserId,
                    isMe: player.userId != null && player.userId == myUserId,
                    canEdit: _canEdit(player),
                  ),
              ],
            ],

            if (state.inactive.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.playersRemoved,
                style: const TextStyle(
                  color: AppColors.neutral,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final player in state.inactive)
                _PlayerRow(
                  player: player,
                  isOwnerRow:
                      player.userId != null && player.userId == ownerUserId,
                  isMe: player.userId != null && player.userId == myUserId,
                  canEdit: _canEdit(player),
                ),
            ],

            const SizedBox(height: AppSpacing.md),

            if (_isOwner)
              AdaptiveButton(
                label: l10n.playersAddDummy,
                kind: AdaptiveButtonKind.tinted,
                busy: state.busy,
                onPressed: () => _add(context),
              )
            else if (!isRegistered)
              GuestNotice(message: l10n.playersGuestCannotAdd),

            if (state.actionFailure != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  state.actionFailure!.localized(l10n),
                  style: const TextStyle(color: AppColors.negative),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _canEdit(Player player) {
    if (!isRegistered) return false;
    if (_isOwner) return true;
    return player.userId != null && player.userId == myUserId;
  }

  Future<void> _add(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PlayersCubit>();

    final name = await showPlayerNameSheet(
      context,
      title: l10n.playersAddTitle,
      subtitle: l10n.playersAddSubtitle,
      submitLabel: l10n.playersAddDummy,
    );
    if (name != null) await cubit.addPlaceholder(name);
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
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
    final l10n = AppLocalizations.of(context);

    final badges = [
      if (isMe) l10n.playersYou,
      if (isOwnerRow) l10n.playersOwner,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: AppColors.neutral.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: player.isActive ? null : AppColors.neutral,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      badges.join(' · '),
                      style: const TextStyle(
                        color: AppColors.neutral,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canEdit)
              AdaptiveButton(
                label: l10n.playersEdit,
                kind: AdaptiveButtonKind.plain,
                expand: false,
                onPressed: () => _showActions(context),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PlayersCubit>();

    final action = await showAdaptiveSheet<PlayerAction>(
      context,
      builder: (sheetContext) =>
          _PlayerActionSheet(player: player, canRemove: !isMe),
    );
    if (action == null) return;

    switch (action) {
      case PlayerAction.rename:
        if (!context.mounted) return;
        final name = await showPlayerNameSheet(
          context,
          title: l10n.playersRenameTitle,
          submitLabel: l10n.commonSave,
          initialValue: player.displayName,
        );
        if (name != null && name != player.displayName) {
          await cubit.rename(player.id, name);
        }

      case PlayerAction.remove:
        if (!context.mounted) return;
        final confirmed = await showAdaptiveConfirm(
          context,
          title: l10n.playersRemoveConfirmTitle(player.displayName),
          message: l10n.playersRemoveConfirmBody,
          confirmLabel: l10n.playersRemove,
          cancelLabel: l10n.commonCancel,
          destructive: true,
        );
        if (confirmed) await cubit.setActive(player.id, isActive: false);

      case PlayerAction.restore:
        await cubit.setActive(player.id, isActive: true);
    }
  }
}

class _PlayerActionSheet extends StatelessWidget {
  const _PlayerActionSheet({required this.player, required this.canRemove});
  final Player player;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            player.displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),

          AdaptiveButton(
            label: l10n.playersRename,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () => Navigator.of(context).pop(PlayerAction.rename),
          ),

          if (!player.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: l10n.playersRestore,
              kind: AdaptiveButtonKind.tinted,
              onPressed: () => Navigator.of(context).pop(PlayerAction.restore),
            ),
          ] else if (canRemove) ...[
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: l10n.playersRemove,
              kind: AdaptiveButtonKind.destructive,
              onPressed: () => Navigator.of(context).pop(PlayerAction.remove),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: l10n.commonCancel,
            kind: AdaptiveButtonKind.plain,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
