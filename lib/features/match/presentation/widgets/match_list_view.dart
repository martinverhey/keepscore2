import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/guest_notice.dart';
import '../cubit/match_list_cubit.dart';
import 'match_day_group.dart';
import 'match_day_label.dart';
import 'match_tile.dart';

class MatchListView extends StatelessWidget {
  const MatchListView({
    super.key,
    required this.isRegistered,
    required this.hasPlayers,
    required this.onOpenMatch,
  });

  final bool isRegistered;
  final bool hasPlayers;
  final void Function(String matchId) onOpenMatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            message: state.failure!.localized(l10n),
            retryLabel: l10n.commonRetry,
            onRetry: cubit.load,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isRegistered) GuestNotice(message: l10n.matchGuestCannotLog),

            if (isRegistered && !hasPlayers)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l10n.matchNeedsPlayers,
                  style: const TextStyle(color: AppColors.neutral, fontSize: 13),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            if (state.matches.isEmpty)
              EmptyState(message: l10n.matchesEmpty)
            else
              for (final group in groupByDay(state.matches)) ...[
                _DayHeader(day: group.day),
                for (final match in group.matches)
                  MatchTile(match: match, onTap: () => onOpenMatch(match.id)),
              ],

            if (state.hasMore)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: AdaptiveButton(
                  label: l10n.matchLoadMore,
                  kind: AdaptiveButtonKind.plain,
                  busy: state.loadingMore,
                  onPressed: cubit.loadMore,
                ),
              ),

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
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        matchDayLabel(context, day),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral,
        ),
      ),
    );
  }
}
