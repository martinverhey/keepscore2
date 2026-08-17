import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/game_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/hint_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../cubit/match_list_cubit.dart';
import 'day_header.dart';
import 'match_day_group.dart';
import 'match_tile.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({
    super.key,
    required this.isRegistered,
    required this.hasPlayers,
    required this.isOwner,
    required this.myPlayerId,
    required this.onOpenMatch,
    required this.onCreateMatch,
  });

  final bool isRegistered;
  final bool hasPlayers;
  final bool isOwner;
  final String? myPlayerId;
  final void Function(String matchId) onOpenMatch;
  final VoidCallback onCreateMatch;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchListCubit>();

    return BlocBuilder<MatchListCubit, MatchListState>(
      builder: (context, state) => _body(context, state, cubit),
    );
  }

  Widget _body(
    BuildContext context,
    MatchListState state,
    MatchListCubit cubit,
  ) {
    return switch (state) {
      MatchListLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      ),
      MatchListFailed(:final failure) => ErrorRetry(
        message: failure.localized(context.l10n),
        retryLabel: context.l10n.commonRetry,
        onRetry: cubit.load,
      ),
      MatchListReady() => _list(context, state, cubit),
    };
  }

  Widget _list(
    BuildContext context,
    MatchListReady state,
    MatchListCubit cubit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isRegistered)
          GuestNotice(message: context.l10n.matchGuestCannotLog),
        if (isRegistered && hasPlayers) _needsPlayersHint(context),
        const SizedBox(height: AppSpacing.lg),
        _matchesSection(context, state),
        if (state.hasMore) _loadMoreButton(context, state, cubit),
        if (state.actionFailure != null) _actionFailureText(context, state),
      ],
    );
  }

  Widget _needsPlayersHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(context.l10n.matchNeedsPlayers, style: AppTypography.caption),
    );
  }

  Widget _matchesSection(BuildContext context, MatchListReady state) {
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AdaptiveLoader(),
      );
    }

    if (state.matches.isEmpty) return _emptyState(context, state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groupByDay(state.matches)) ...[
          DayHeader(day: group.day),
          for (final match in group.matches)
            MatchTile(
              match: match,
              myPlayerId: myPlayerId,
              onTap: () => onOpenMatch(match.id),
            ),
        ],
      ],
    );
  }

  Widget _emptyState(BuildContext context, MatchListReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(
          message: state.selectedGameType == null
              ? context.l10n.matchesEmpty
              : context.l10n.matchesFilterEmpty(
                  state.selectedGameType!.label(context),
                ),
        ),
        if (isOwner && state.selectedGameType == null) ...[
          const SizedBox(height: AppSpacing.sm),
          HintCard(
            message: context.l10n.matchesCreateHint,
            actionLabel: context.l10n.matchesCreateHintAction,
            onAction: onCreateMatch,
          ),
        ],
      ],
    );
  }

  Widget _loadMoreButton(
    BuildContext context,
    MatchListReady state,
    MatchListCubit cubit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AdaptiveButton(
        label: context.l10n.matchLoadMore,
        kind: AdaptiveButtonKind.plain,
        busy: state.loadingMore,
        onPressed: cubit.loadMore,
      ),
    );
  }

  Widget _actionFailureText(BuildContext context, MatchListReady state) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        state.actionFailure!.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }
}
