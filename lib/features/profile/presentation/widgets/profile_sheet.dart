import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/error/failure_messages.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/medal.extension.dart';
import '../../../../core/extensions/season.extension.dart';
import '../../../../core/extensions/streak_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/today_delta_badge.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../../leaderboard/domain/season_leaderboard.model.dart';
import '../../../match/domain/match_entry.model.dart';
import '../../../match/presentation/widgets/match_card.dart';
import '../cubit/profile_history_cubit.dart';
import '../cubit/profile_overview_cubit.dart';
import '../cubit/profile_versus_cubit.dart';
import 'initials_circle.dart';
import 'rating_trend_chart.dart';

enum ProfileTab { overview, versus, history }

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
  ProfileVersusCubit? _versusCubit;
  ProfileHistoryCubit? _historyCubit;

  @override
  void dispose() {
    _versusCubit?.close();
    _historyCubit?.close();
    super.dispose();
  }

  ProfileVersusCubit _ensureVersusCubit(BuildContext context) {
    final cubit = _versusCubit;
    if (cubit != null) return cubit;
    final overview = context.read<ProfileOverviewCubit>();
    return _versusCubit = getIt<ProfileVersusCubit>(
      param1: overview.playerId,
      param2: widget.myPlayerId,
    )..load();
  }

  ProfileHistoryCubit _ensureHistoryCubit(BuildContext context) {
    final cubit = _historyCubit;
    if (cubit != null) return cubit;
    final overview = context.read<ProfileOverviewCubit>();
    return _historyCubit = getIt<ProfileHistoryCubit>(
      param1: overview.competitionId,
      param2: overview.playerId,
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileOverviewCubit>();

    return BlocBuilder<ProfileOverviewCubit, ProfileOverviewState>(
      builder: (context, state) {
        return Sheet(
          title: widget.displayName,
          avatar: InitialsCircle(displayName: widget.displayName, size: 48),
          subtitleWidget: state is ProfileOverviewReady
              ? _medalSummary(state)
              : null,
          content: switch (state) {
            ProfileOverviewLoading() => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: AdaptiveLoader(),
            ),
            ProfileOverviewFailed(:final failure) => ErrorRetry(
              message: failure.localized(context.l10n),
              retryLabel: context.l10n.commonRetry,
              onRetry: cubit.load,
            ),
            ProfileOverviewReady() => _ready(context, state),
          },
        );
      },
    );
  }

  Widget _ready(BuildContext context, ProfileOverviewReady state) {
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
            ProfileTab.history: context.l10n.profileTabHistory,
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (_tab) {
          ProfileTab.overview => _overview(context, state),
          ProfileTab.versus => _versusTab(context),
          ProfileTab.history => _historyTab(context),
        },
      ],
    );
  }

  Widget _overview(BuildContext context, ProfileOverviewReady state) {
    final leaderboard = state.leaderboard;

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
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.profileGamesTitle, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          _gamesRow(context, state),
          const SizedBox(height: AppSpacing.md),
          _streaksRow(context, state),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.profileTrendTitle, style: AppTypography.bodyMedium),
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
        if (state.recentMatches.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _recentMatches(context, state.recentMatches),
        ],
      ],
    );
  }

  Widget _versusTab(BuildContext context) {
    final cubit = _ensureVersusCubit(context);

    return BlocBuilder<ProfileVersusCubit, ProfileVersusState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        ProfileVersusLoading() => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: AdaptiveLoader(),
        ),
        ProfileVersusFailed(:final failure) => ErrorRetry(
          message: failure.localized(context.l10n),
          retryLabel: context.l10n.commonRetry,
          onRetry: cubit.load,
        ),
        ProfileVersusReady() => _versus(context, state),
      },
    );
  }

  Widget _versus(BuildContext context, ProfileVersusReady state) {
    final record = state.headToHead;
    if (record.wins + record.losses + record.draws == 0) {
      return EmptyState(
        message: context.l10n.profileVersusEmpty(widget.displayName),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _recordTable(
          context,
          wins: record.wins,
          losses: record.losses,
          draws: record.draws,
        ),
        if (state.recentMatches.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _recentMatches(context, state.recentMatches),
        ],
      ],
    );
  }

  Widget? _medalSummary(ProfileOverviewReady state) {
    final tally = state.medals;
    if (tally == null || !tally.hasAny) return null;

    return _medalRow(tally);
  }

  Widget _medalRow(Medals medals) {
    final chips = _medalChips(medals);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
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
    ProfileOverviewReady state,
    Leaderboard leaderboard,
  ) {
    return _statCard([
      _seasonRatingBlock(context, leaderboard),
      _statBlock(
        context.l10n.profileBestRatingLabel,
        state.bestRating.ratingLabel,
      ),
    ]);
  }

  Widget _statCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: AppRadius.card,
      ),
      child: Row(children: children),
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
                leaderboard.rating.ratingLabel,
                style: AppTypography.titleSmall.copyWith(
                  fontFeatures: AppTypography.tabularFigures,
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
            style: AppTypography.labelTiny,
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
        color: AppColors.neutralSurface,
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
            style: AppTypography.titleSmall.copyWith(
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelTiny,
          ),
        ],
      ),
    );
  }

  Widget _gamesRow(BuildContext context, ProfileOverviewReady state) {
    return _statCard([
      _statBlock(
        context.l10n.profileTodayGamesLabel,
        '${state.recentPlayed.today}',
      ),
      _statBlock(
        context.l10n.profileThisWeekGamesLabel,
        '${state.recentPlayed.week}',
      ),
      _statBlock(
        context.l10n.profileSeasonGamesLabel,
        '${state.leaderboard?.played ?? 0}',
      ),
      _statBlock(context.l10n.profileTotalGamesLabel, '${state.totalPlayed}'),
    ]);
  }

  Widget _streaksRow(BuildContext context, ProfileOverviewReady state) {
    final streak = state.streak;
    final winStreak = streak.type == StreakType.win ? streak.count : 0;
    final tier = streak.type.tier(winStreak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statCard([
          if (tier > 0) ...[
            _tierFirePill(tier),
            const SizedBox(width: AppSpacing.sm),
          ],
          _statBlock(context.l10n.profileWinStreakLabel, '$winStreak'),
          _statBlock(
            context.l10n.profileBestWinStreakLabel,
            '${state.bestStreaks.win}',
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        _streakMilestoneRow(context),
      ],
    );
  }

  Widget _tierFirePill(int flameCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        color: AppColors.fireBadgeFill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < flameCount; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            const AdaptiveIcon(
              AdaptiveGlyph.fire,
              color: AppColors.fireCore,
              size: 13,
            ),
          ],
        ],
      ),
    );
  }

  Widget _streakMilestoneRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _streakMilestoneItem(context, flameCount: 1, wins: 3)),
        Expanded(child: _streakMilestoneItem(context, flameCount: 2, wins: 5)),
        Expanded(child: _streakMilestoneItem(context, flameCount: 3, wins: 10)),
      ],
    );
  }

  Widget _streakMilestoneItem(
    BuildContext context, {
    required int flameCount,
    required int wins,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tierFirePill(flameCount),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            '= ${context.l10n.profileStreakMilestoneWins(wins)}',
            style: AppTypography.labelTiny,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _recentMatches(BuildContext context, List<MatchEntry> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.profileRecentMatchesTitle,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final match in matches) _recentMatchTile(match),
      ],
    );
  }

  Widget _recentMatchTile(MatchEntry match) {
    return MatchCard(match: match, myPlayerId: widget.myPlayerId);
  }

  Widget _historyTab(BuildContext context) {
    final cubit = _ensureHistoryCubit(context);

    return BlocBuilder<ProfileHistoryCubit, ProfileHistoryState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        ProfileHistoryLoading() => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: AdaptiveLoader(),
        ),
        ProfileHistoryFailed(:final failure) => ErrorRetry(
          message: failure.localized(context.l10n),
          retryLabel: context.l10n.commonRetry,
          onRetry: cubit.load,
        ),
        ProfileHistoryReady() => _history(context, state),
      },
    );
  }

  Widget _history(BuildContext context, ProfileHistoryReady state) {
    if (state.leaderboards.isEmpty) {
      return EmptyState(message: context.l10n.profileHistoryEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final leaderboard in state.leaderboards)
          _historyRow(context, leaderboard),
      ],
    );
  }

  Widget _historyRow(BuildContext context, SeasonLeaderboard leaderboard) {
    final medal = leaderboard.medal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              leaderboard.season.label(context, widget.seasonLength),
              style: AppTypography.bodySmall,
            ),
          ),
          if (medal != null) ...[
            AdaptiveIcon(AdaptiveGlyph.medal, color: medal.color, size: 16),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text('#${leaderboard.rank}', style: AppTypography.caption),
          const SizedBox(width: AppSpacing.sm),
          Text(
            leaderboard.rating.ratingLabel,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
