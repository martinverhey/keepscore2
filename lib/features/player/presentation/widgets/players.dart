import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keepscore2/core/widgets/section_label.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../domain/player.model.dart';
import '../cubit/players_cubit.dart';
import 'player_name_sheet.dart';
import 'player_row.dart';

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
    final cubit = context.read<PlayersCubit>();

    return BlocBuilder<PlayersCubit, PlayersState>(
      builder: (context, state) => _body(context, state, cubit),
    );
  }

  Widget _body(BuildContext context, PlayersState state, PlayersCubit cubit) {
    if (state.status == PlayersStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      );
    }

    if (state.status == PlayersStatus.failed && state.players.isEmpty) {
      return ErrorRetry(
        message: state.failure!.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      );
    }

    return _list(context, state);
  }

  Widget _list(BuildContext context, PlayersState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isRegistered) ...[
          GuestNotice(message: context.l10n.playersGuestCannotAdd),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.active.isEmpty)
          EmptyState(message: context.l10n.playersEmpty)
        else
          for (final player in state.active) _playerRow(player),
        if (state.inactive.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionLabel(context.l10n.playersRemoved),
          for (final player in state.inactive) _playerRow(player),
        ],
        const SizedBox(height: AppSpacing.md),
        if (_isOwner) _addPlaceholderButton(context, state),
        if (state.actionFailure != null) _actionFailureText(context, state),
      ],
    );
  }

  Widget _playerRow(Player player) {
    return PlayerRow(
      player: player,
      isOwnerRow: player.userId != null && player.userId == ownerUserId,
      isMe: player.userId != null && player.userId == myUserId,
      canEdit: _canEdit(player),
    );
  }

  Widget _addPlaceholderButton(BuildContext context, PlayersState state) {
    return AdaptiveButton(
      label: context.l10n.playersAddDummy,
      kind: AdaptiveButtonKind.tinted,
      busy: state.busy,
      onPressed: () => addPlaceholderPlayer(context),
    );
  }

  Widget _actionFailureText(BuildContext context, PlayersState state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        state.actionFailure!.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }

  bool _canEdit(Player player) {
    if (!isRegistered) return false;
    if (_isOwner) return true;
    return player.userId != null && player.userId == myUserId;
  }
}

Future<void> addPlaceholderPlayer(BuildContext context) async {
  final cubit = context.read<PlayersCubit>();

  final name = await showPlayerNameSheet(
    context,
    title: context.l10n.playersAddTitle,
    subtitle: context.l10n.playersAddSubtitle,
    submitLabel: context.l10n.playersAddDummy,
  );
  if (name != null) await cubit.addPlaceholder(name);
}
