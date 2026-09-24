import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/rating_point_list.extension.dart';
import '../../../../core/extensions/streak_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/sparkline.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../../core/widgets/trophy_chip.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../../domain/rating_point.model.dart';
import '../cubit/profile_overview_cubit.dart';
import 'initials_circle.dart';
import '../pages/profile_sheet.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.competitionId,
    required this.playerId,
    required this.displayName,
    required this.seasonLength,
    this.leaderboard,
    this.medals,
    this.trend = const [],
  });

  final String competitionId;
  final String playerId;
  final String displayName;
  final SeasonLength seasonLength;
  final Leaderboard? leaderboard;
  final Medals? medals;
  final List<RatingPoint> trend;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.lg),
  );

  @override
  Widget build(BuildContext context) {
    return AdaptiveTappable(
      onTap: () => _openProfile(context),
      borderRadius: _radius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: _radius,
          color: AdaptiveColors.modalSurface(context),
          border: Border.all(
            color: AppColors.neutral.withValues(
              alpha: AppOpacity.controlBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: _details(context)),
            const SizedBox(width: AppSpacing.sm),
            const AdaptiveIcon(
              AdaptiveGlyph.chevronRight,
              size: 18,
              color: AppColors.neutral,
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    showAdaptiveSheet<void>(
      context,
      builder: (_) => BlocProvider(
        create: (_) =>
            getIt<ProfileOverviewCubit>(param1: competitionId, param2: playerId)
              ..load(viewerPlayerId: playerId),
        child: ProfileSheet(
          displayName: displayName,
          seasonLength: seasonLength,
          myPlayerId: playerId,
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    final leaderboard = this.leaderboard;
    final hasStats = leaderboard != null && leaderboard.played > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context),
        if (hasStats) ...[
          const SizedBox(height: AppSpacing.md),
          _statRow(context, leaderboard),
        ],
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        InitialsCircle(displayName: displayName, size: 44),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _nameRow(),
              if (_awardsRow() case final awards?) ...[
                const SizedBox(height: 2),
                awards,
              ],
            ],
          ),
        ),
        _trendSparkline(context),
      ],
    );
  }

  Widget _nameRow() => Row(
    children: [
      Flexible(
        child: Text(
          displayName,
          style: AppTypography.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (_streakBadge() case final badge?) ...[
        const SizedBox(width: AppSpacing.xs),
        badge,
      ],
    ],
  );

  Widget? _streakBadge() {
    final leaderboard = this.leaderboard;
    if (leaderboard == null ||
        !leaderboard.streakType.hasBadge(leaderboard.streakCount)) {
      return null;
    }

    return StreakBadge(
      type: leaderboard.streakType,
      count: leaderboard.streakCount,
    );
  }

  Widget? _awardsRow() {
    final chips = _awardChips();
    if (chips.isEmpty) return null;

    return Row(spacing: AppSpacing.xs, children: chips);
  }

  List<Widget> _awardChips() {
    final trophies = leaderboard?.trophies ?? 0;
    final tally = medals;

    return [
      if (trophies > 0) TrophyChip(count: trophies),
      if (tally != null) ...[
        if (tally.gold > 0) MedalChip(color: AppColors.gold, count: tally.gold),
        if (tally.silver > 0)
          MedalChip(color: AppColors.silver, count: tally.silver),
        if (tally.bronze > 0)
          MedalChip(color: AppColors.bronze, count: tally.bronze),
      ],
    ];
  }

  Widget _trendSparkline(BuildContext context) {
    if (trend.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Sparkline(
        values: trend.ratings,
        color: trend.trendColor(context),
        width: 100,
      ),
    );
  }

  Widget _statRow(BuildContext context, Leaderboard leaderboard) {
    final winRatePercent = leaderboard.played == 0
        ? 0
        : (leaderboard.winRate * 100).round();
    final hasStreak = leaderboard.streakType.hasBadge(leaderboard.streakCount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _statBlock(
          leaderboard.rating.ratingLabel,
          context.l10n.profileSeasonRatingLabel,
        ),
        _statBlock('$winRatePercent%', context.l10n.profileWinRateLabel),
        _statBlock('${leaderboard.played}', context.l10n.matchesTitle),
        if (hasStreak) _streakBlock(context, leaderboard),
      ],
    );
  }

  Widget _streakBlock(BuildContext context, Leaderboard leaderboard) {
    return _statBlock(
      '${leaderboard.streakCount}',
      leaderboard.streakType == StreakType.win
          ? context.l10n.profileWinStreakLabel
          : context.l10n.profileLossStreakLabel,
    );
  }

  Widget _statBlock(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: AppTypography.tabularFigures,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
}
