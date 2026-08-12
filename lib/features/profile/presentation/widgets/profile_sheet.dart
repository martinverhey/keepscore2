import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/stat_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../competition/domain/competition.dart';
import '../../../leaderboard/domain/medal.dart';
import '../../../leaderboard/domain/season_standing.dart';
import '../../../leaderboard/presentation/widgets/season_label.dart';
import '../../domain/head_to_head_record.dart';
import '../../domain/streak.dart';
import '../cubit/profile_cubit.dart';
import 'game_type_label.dart';
import 'initials_circle.dart';
import 'rating_trend_chart.dart';

enum ProfileTab { overview, seasonHistory }

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({
    super.key,
    required this.displayName,
    required this.seasonLength,
  });

  final String displayName;
  final SeasonLength seasonLength;

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  ProfileTab _tab = ProfileTab.overview;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Sheet(
          title: widget.displayName,
          avatar: InitialsCircle(displayName: widget.displayName, size: 48),
          content: switch (state.status) {
            ProfileStatus.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: AdaptiveLoader(),
            ),
            ProfileStatus.failed => ErrorRetry(
              message: state.failure!.localized(context.l10n),
              retryLabel: context.l10n.commonRetry,
              onRetry: cubit.load,
            ),
            ProfileStatus.ready => _ready(context, state),
          },
        );
      },
    );
  }

  Widget _ready(BuildContext context, ProfileState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveSegmented<ProfileTab>(
          value: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
          segments: {
            ProfileTab.overview: context.l10n.profileTabOverview,
            ProfileTab.seasonHistory: context.l10n.profileTabSeasonHistory,
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (_tab) {
          ProfileTab.overview => _overview(context, state),
          ProfileTab.seasonHistory => _seasonHistory(context, state),
        },
      ],
    );
  }

  Widget _overview(BuildContext context, ProfileState state) {
    final standing = state.standing;
    final streak = state.streak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (standing == null)
          EmptyState(message: context.l10n.profileNotEnoughMatches)
        else ...[
          Row(
            children: [
              StatLabel(
                label: context.l10n.profileRank(
                  standing.rank,
                  state.playerCount,
                ),
              ),
              StatLabel(label: formatRating(standing.rating)),
              StatLabel(
                label: context.l10n.leaderboardRecord(
                  standing.wins,
                  standing.losses,
                  standing.draws,
                ),
              ),
              StatLabel(
                label: context.l10n.profileWinRate(
                  standing.played == 0
                      ? 0
                      : (standing.wins / standing.played * 100).round(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.profileTrendTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.history.length < 2)
            EmptyState(message: context.l10n.profileNotEnoughMatches)
          else ...[
            RatingTrendChart(points: state.history),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [RatingDelta(value: state.history.last.ratingDelta)],
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.profileMatchesPlayed(state.totalPlayed),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (streak.type != StreakType.none)
              StreakBadge(
                isWin: streak.type == StreakType.win,
                label: streak.type == StreakType.win
                    ? context.l10n.profileStreakWin(streak.count)
                    : context.l10n.profileStreakLoss(streak.count),
              ),
          ],
        ),
        if (state.headToHead.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.profileHeadToHeadTitle(widget.displayName),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final record in state.headToHead)
            _headToHeadRow(context, record),
        ],
      ],
    );
  }

  Widget _headToHeadRow(BuildContext context, HeadToHeadRecord record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              gameTypeLabel(context, record.gameType),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            context.l10n.leaderboardRecord(
              record.wins,
              record.losses,
              record.draws,
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _seasonHistory(BuildContext context, ProfileState state) {
    if (state.seasonHistory.isEmpty) {
      return EmptyState(message: context.l10n.profileSeasonHistoryEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final standing in state.seasonHistory)
          _seasonHistoryRow(context, standing),
      ],
    );
  }

  Widget _seasonHistoryRow(BuildContext context, SeasonStanding standing) {
    final medal = standing.medal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              seasonLabel(context, standing.season, widget.seasonLength),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (medal != null) ...[
            AdaptiveIcon(
              AdaptiveGlyph.medal,
              color: _medalColor(medal),
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            '#${standing.rank}',
            style: const TextStyle(fontSize: 13, color: AppColors.neutral),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatRating(standing.rating),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _medalColor(Medal medal) => switch (medal) {
    Medal.gold => AppColors.gold,
    Medal.silver => AppColors.silver,
    Medal.bronze => AppColors.bronze,
  };
}
