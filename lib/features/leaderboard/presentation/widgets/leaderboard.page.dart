import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../profile/presentation/widgets/game_type_label.dart';
import '../../domain/season.model.dart';
import '../cubit/leaderboard_cubit.dart';
import 'leaderboard_row.dart';
import 'season_label.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({
    super.key,
    required this.competitionId,
    required this.seasonLength,
    required this.myPlayerId,
    required this.isOwner,
    required this.onManagePlayers,
  });

  final String competitionId;
  final SeasonLength seasonLength;
  final String? myPlayerId;
  final bool isOwner;
  final VoidCallback onManagePlayers;

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
            state.leaderboards.isEmpty) {
          return ErrorRetry(
            message: state.failure!.localized(context.l10n),
            retryLabel: context.l10n.commonRetry,
            onRetry: cubit.load,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.season != null) _seasonBar(context, state.season!),
            const SizedBox(height: AppSpacing.md),

            if (state.busy)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: AdaptiveLoader(),
              )
            else if (state.leaderboards.isEmpty)
              EmptyState(
                message: state.selectedGameType == null
                    ? context.l10n.leaderboardNoPlayers
                    : context.l10n.leaderboardFilterEmpty(
                        gameTypeLabel(context, state.selectedGameType!),
                      ),
              )
            else
              for (final leaderboard in state.leaderboards)
                LeaderboardRow(
                  competitionId: competitionId,
                  leaderboard: leaderboard,
                  isMe: leaderboard.playerId == myPlayerId,
                  myPlayerId: myPlayerId,
                  seasonLength: seasonLength,
                  medals: state.medals[leaderboard.playerId],
                ),

            if (isOwner) ...[
              const SizedBox(height: AppSpacing.md),
              AdaptiveButton(
                label: context.l10n.playersManageTitle,
                kind: AdaptiveButtonKind.tinted,
                onPressed: onManagePlayers,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _seasonBar(BuildContext context, Season season) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          seasonLabel(context, season, seasonLength),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.leaderboardSeasonEnds(
            DateFormat.MMMd(locale).format(season.endsAt),
          ),
          style: const TextStyle(color: AppColors.neutral, fontSize: 12),
        ),
      ],
    );
  }
}
