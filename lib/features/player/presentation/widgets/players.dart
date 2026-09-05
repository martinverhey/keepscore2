import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keepscore2/core/widgets/section_label.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../domain/player.model.dart';
import '../cubit/players_cubit.dart';
import '../pages/player_name_sheet.dart';
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
    return switch (state) {
      PlayersLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      ),
      PlayersFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      PlayersReady() => _list(context, state),
    };
  }

  Widget _list(BuildContext context, PlayersReady state) {
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
        if (state.actionFailure case final failure?) FailureText(failure),
      ],
    );
  }

  Widget _playerRow(Player player) {
    final isMe = player.userId != null && player.userId == myUserId;
    return PlayerRow(
      player: player,
      isOwnerRow: player.userId != null && player.userId == ownerUserId,
      isMe: isMe,
      canRename: _canRename(player, isMe: isMe),
      canRemove: _canRemove(isMe: isMe),
    );
  }

  bool _canRename(Player player, {required bool isMe}) {
    if (!isRegistered) return false;
    if (isMe) return true;
    return _isOwner && player.isPlaceholder;
  }

  bool _canRemove({required bool isMe}) => isRegistered && _isOwner && !isMe;
}

Future<void> addPlaceholderPlayer(BuildContext context) async {
  final cubit = context.read<PlayersCubit>();

  final name = await showPlayerNameSheet(
    context,
    title: context.l10n.playersAddTitle,
    subtitle: context.l10n.playersAddSubtitle,
    submitLabel: context.l10n.playersAddPlayer,
  );
  if (name != null) await cubit.addPlaceholder(name);
}
