import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/streak_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../leaderboard/domain/leaderboard.model.dart';
import '../../../leaderboard/domain/medals.model.dart';
import '../cubit/profile_overview_cubit.dart';
import 'initials_circle.dart';
import 'profile_sheet.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.competitionId,
    required this.playerId,
    required this.displayName,
    required this.seasonLength,
    this.leaderboard,
    this.medals,
  });

  final String competitionId;
  final String playerId;
  final String displayName;
  final SeasonLength seasonLength;
  final Leaderboard? leaderboard;
  final Medals? medals;

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.accent(context);
    final leaderboard = this.leaderboard;
    final hasStats = leaderboard != null && leaderboard.played > 0;

    return AdaptiveTappable(
      onTap: () => showAdaptiveSheet<void>(
        context,
        builder: (_) => BlocProvider(
          create: (_) => getIt<ProfileOverviewCubit>(
            param1: competitionId,
            param2: playerId,
          )..load(viewerPlayerId: playerId),
          child: ProfileSheet(
            displayName: displayName,
            seasonLength: seasonLength,
            myPlayerId: playerId,
          ),
        ),
      ),
      borderRadius: AppRadius.card,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: AppOpacity.cardFillFaint),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: accent.withValues(alpha: AppOpacity.badgeFill),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            if (hasStats) ...[
              const SizedBox(height: AppSpacing.md),
              _statRow(context, leaderboard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final tally = medals;
    final hasMedals = tally != null && tally.hasAny;

    return Row(
      children: [
        InitialsCircle(displayName: displayName, size: 44),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: AppTypography.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasMedals) ...[
                const SizedBox(height: 2),
                Row(children: _medalChips(tally)),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const AdaptiveIcon(
          AdaptiveGlyph.chevronRight,
          size: 18,
          color: AppColors.neutral,
        ),
      ],
    );
  }

  List<Widget> _medalChips(Medals medals) {
    final chips = [
      if (medals.gold > 0) MedalChip(color: AppColors.gold, count: medals.gold),
      if (medals.silver > 0)
        MedalChip(color: AppColors.silver, count: medals.silver),
      if (medals.bronze > 0)
        MedalChip(color: AppColors.bronze, count: medals.bronze),
    ];
    return [
      for (var i = 0; i < chips.length; i++) ...[
        if (i > 0) const SizedBox(width: AppSpacing.xs),
        chips[i],
      ],
    ];
  }

  Widget _statRow(BuildContext context, Leaderboard leaderboard) {
    final winRatePercent = leaderboard.played == 0
        ? 0
        : (leaderboard.winRate * 100).round();
    final hasStreak = leaderboard.streakType.tier(leaderboard.streakCount) > 0;

    return Row(
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
    final isWin = leaderboard.streakType == StreakType.win;

    return _statBlock(
      '${leaderboard.streakCount}',
      isWin
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
