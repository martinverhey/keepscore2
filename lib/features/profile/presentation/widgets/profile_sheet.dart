import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../../core/widgets/today_delta_badge.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medal.enum.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../leaderboard/domain/season_standing.model.dart';
import '../../../leaderboard/presentation/widgets/game_type_filter_dropdown.dart';
import '../../../leaderboard/presentation/widgets/season_label.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../../match/presentation/cubit/game_type_filter_cubit.dart';
import '../../../match/presentation/widgets/match_tile.dart';
import '../cubit/profile_cubit.dart';
import 'initials_circle.dart';
import 'rating_trend_chart.dart';

enum ProfileTab { overview, versus, seasonHistory }

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({
    super.key,
    required this.displayName,
    required this.seasonLength,
    this.myPlayerId,
  });

  final String displayName;
  final SeasonLength seasonLength;
  final String? myPlayerId;

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
          subtitleWidget: state.leaderboard == null
              ? null
              : _rankSummary(context, state),
          headerTrailing: state.status == ProfileStatus.loading
              ? null
              : GameTypeFilterDropdown(
                  selected: context.watch<GameTypeFilterCubit>().state,
                  onSelected: context.read<GameTypeFilterCubit>().select,
                ),
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
            if (state.hasOpponent)
              ProfileTab.versus: context.l10n.profileTabVersus,
            ProfileTab.seasonHistory: context.l10n.profileTabSeasonHistory,
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (_tab) {
          ProfileTab.overview => _overview(context, state),
          ProfileTab.versus => _versus(context, state),
          ProfileTab.seasonHistory => _seasonHistory(context, state),
        },
      ],
    );
  }

  Widget _overview(BuildContext context, ProfileState state) {
    final leaderboard = state.leaderboard;
    final streak = state.streak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leaderboard == null)
          EmptyState(message: context.l10n.profileNotEnoughMatches)
        else ...[
          _ratingSummary(context, state, leaderboard),
          const SizedBox(height: AppSpacing.md),
          _recordTable(
            context,
            wins: leaderboard.wins,
            losses: leaderboard.losses,
            draws: leaderboard.draws,
          ),
          const SizedBox(height: AppSpacing.md),
          _gamesCountRow(context, state),
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
        if (streak.type != StreakType.none) ...[
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: StreakBadge(
              isWin: streak.type == StreakType.win,
              label: streak.type == StreakType.win
                  ? context.l10n.profileStreakWin(streak.count)
                  : context.l10n.profileStreakLoss(streak.count),
            ),
          ),
        ],
        if (state.recentMatches.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _recentMatches(context, state.recentMatches),
        ],
      ],
    );
  }

  Widget _versus(BuildContext context, ProfileState state) {
    final records = state.versusRecords;
    if (records.isEmpty) {
      return EmptyState(
        message: context.l10n.profileVersusEmpty(widget.displayName),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _recordTable(
          context,
          wins: records.fold(0, (sum, record) => sum + record.wins),
          losses: records.fold(0, (sum, record) => sum + record.losses),
          draws: records.fold(0, (sum, record) => sum + record.draws),
        ),
        if (state.versusRecentMatches.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _recentMatches(context, state.versusRecentMatches),
        ],
      ],
    );
  }

  Widget _rankSummary(BuildContext context, ProfileState state) {
    final leaderboard = state.leaderboard!;
    final tally = state.medals;

    return Row(
      children: [
        Flexible(
          child: Text(
            context.l10n.profileRank(leaderboard.rank, state.playerCount),
            style: const TextStyle(fontSize: 12, color: AppColors.neutral),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tally != null && tally.hasAny) ...[
          const Spacer(),
          _medalRow(tally),
          const Spacer(),
        ],
      ],
    );
  }

  Widget _medalRow(Medals medals) {
    final chips = _medalChips(medals);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          chips[i],
        ],
      ],
    );
  }

  List<Widget> _medalChips(Medals medals) {
    return [
      if (medals.gold > 0) MedalChip(color: AppColors.gold, count: medals.gold),
      if (medals.silver > 0)
        MedalChip(color: AppColors.silver, count: medals.silver),
      if (medals.bronze > 0)
        MedalChip(color: AppColors.bronze, count: medals.bronze),
    ];
  }

  Widget _ratingSummary(
    BuildContext context,
    ProfileState state,
    Leaderboard leaderboard,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          _seasonRatingBlock(context, leaderboard),
          _statBlock(
            context.l10n.profileBestRatingLabel,
            formatRating(state.bestRating),
          ),
        ],
      ),
    );
  }

  Widget _seasonRatingBlock(BuildContext context, Leaderboard leaderboard) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatRating(leaderboard.rating),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (leaderboard.todayDelta != 0) ...[
                const SizedBox(width: AppSpacing.xs),
                TodayDeltaBadge(delta: leaderboard.todayDelta),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.profileSeasonRatingLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral),
          ),
        ],
      ),
    );
  }

  Widget _recordTable(
    BuildContext context, {
    required int wins,
    required int losses,
    required int draws,
  }) {
    final played = wins + losses + draws;
    final winRatePercent = played == 0 ? 0 : (wins / played * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.neutral.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          _statBlock(context.l10n.profileWinsLabel, '$wins'),
          _statBlock(context.l10n.profileLossesLabel, '$losses'),
          _statBlock(context.l10n.profileDrawsLabel, '$draws'),
          _statBlock(context.l10n.profileWinRateLabel, '$winRatePercent%'),
        ],
      ),
    );
  }

  Widget _statBlock(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral),
          ),
        ],
      ),
    );
  }

  Widget _gamesCountRow(BuildContext context, ProfileState state) {
    return Row(
      children: [
        _statBlock(
          context.l10n.profileSeasonGamesLabel,
          '${state.leaderboard?.played ?? 0}',
        ),
        _statBlock(context.l10n.profileTotalGamesLabel, '${state.totalPlayed}'),
      ],
    );
  }

  Widget _recentMatches(BuildContext context, List<MatchEntry> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.profileRecentMatchesTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final match in matches) _recentMatchTile(match),
      ],
    );
  }

  Widget _recentMatchTile(MatchEntry match) {
    return MatchTile(
      match: match,
      myPlayerId: widget.myPlayerId,
      onTap: () => context.push(Routes.match(match.competitionId, match.id)),
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
