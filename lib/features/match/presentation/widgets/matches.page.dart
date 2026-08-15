import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/hint_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../../../profile/presentation/widgets/game_type_label.dart';
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
      builder: (context, state) {
        if (state.status == MatchListStatus.loading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AdaptiveLoader(),
          );
        }

        if (state.status == MatchListStatus.failed && state.matches.isEmpty) {
          return ErrorRetry(
            message: state.failure!.localized(context.l10n),
            retryLabel: context.l10n.commonRetry,
            onRetry: cubit.load,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isRegistered)
              GuestNotice(message: context.l10n.matchGuestCannotLog),

            if (isRegistered && hasPlayers)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  context.l10n.matchNeedsPlayers,
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            if (state.busy)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: AdaptiveLoader(),
              )
            else if (state.matches.isEmpty) ...[
              EmptyState(
                message: state.selectedGameType == null
                    ? context.l10n.matchesEmpty
                    : context.l10n.matchesFilterEmpty(
                        gameTypeLabel(context, state.selectedGameType!),
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
            ] else
              for (final group in groupByDay(state.matches)) ...[
                DayHeader(day: group.day),
                for (final match in group.matches)
                  MatchTile(
                    match: match,
                    myPlayerId: myPlayerId,
                    onTap: () => onOpenMatch(match.id),
                  ),
              ],

            if (state.hasMore)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: AdaptiveButton(
                  label: context.l10n.matchLoadMore,
                  kind: AdaptiveButtonKind.plain,
                  busy: state.loadingMore,
                  onPressed: cubit.loadMore,
                ),
              ),

            if (state.actionFailure != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  state.actionFailure!.localized(context.l10n),
                  style: const TextStyle(color: AppColors.negative),
                ),
              ),
          ],
        );
      },
    );
  }
}
