import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../competition/domain/competition.dart';
import '../cubit/leaderboard_cubit.dart';
import 'leaderboard_row.dart';
import 'season_label.dart';
import 'season_sheet.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({
    super.key,
    required this.competitionId,
    required this.seasonLength,
    required this.myPlayerId,
    required this.isOwner,
  });

  final String competitionId;
  final SeasonLength seasonLength;
  final String? myPlayerId;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LeaderboardCubit>();

    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        if (state.status == LeaderboardStatus.loading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AdaptiveLoader(),
          );
        }

        if (state.status == LeaderboardStatus.failed &&
            state.standings.isEmpty) {
          return ErrorRetry(
            message: state.failure!.localized(context.l10n),
            retryLabel: context.l10n.commonRetry,
            onRetry: cubit.load,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.selectedSeason != null)
              _seasonBar(
                context,
                state,
                onPick: () => _pickSeason(context, state),
              ),
            const SizedBox(height: AppSpacing.md),

            if (state.busy)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: AdaptiveLoader(),
              )
            else if (state.standings.isEmpty)
              EmptyState(message: context.l10n.leaderboardNoPlayers)
            else
              for (final standing in state.standings)
                LeaderboardRow(
                  competitionId: competitionId,
                  standing: standing,
                  isMe: standing.playerId == myPlayerId,
                  myPlayerId: myPlayerId,
                  seasonLength: seasonLength,
                  medals: state.medals[standing.playerId],
                ),

            if (isOwner) ...[
              const SizedBox(height: AppSpacing.md),
              AdaptiveButton(
                label: context.l10n.playersManageTitle,
                kind: AdaptiveButtonKind.tinted,
                onPressed: () => context.push(Routes.players(competitionId)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _seasonBar(
    BuildContext context,
    LeaderboardState state, {
    required VoidCallback onPick,
  }) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final season = state.selectedSeason!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                seasonLabel(context, season, seasonLength),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state.isShowingCurrentSeason) ...[
                const SizedBox(height: 2),
                Text(
                  context.l10n.leaderboardSeasonEnds(
                    DateFormat.MMMd(locale).format(season.endsAt),
                  ),
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (state.hasHistory)
          AdaptiveButton(
            label: context.l10n.leaderboardPickSeason,
            kind: AdaptiveButtonKind.plain,
            expand: false,
            onPressed: onPick,
          ),
      ],
    );
  }

  Future<void> _pickSeason(BuildContext context, LeaderboardState state) async {
    final cubit = context.read<LeaderboardCubit>();

    final startsAt = await showAdaptiveSheet<DateTime>(
      context,
      builder: (_) => SeasonSheet(state: state, seasonLength: seasonLength),
    );
    if (startsAt != null) await cubit.selectSeason(startsAt);
  }
}
