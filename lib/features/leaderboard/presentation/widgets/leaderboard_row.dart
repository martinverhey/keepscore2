import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/double.extension.dart';
import '../../../../core/extensions/int.extension.dart';
import '../../../../core/extensions/medal.extension.dart';
import '../../../../core/extensions/streak_type.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/tag.dart';
import '../../../../core/widgets/today_delta_badge.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../profile/presentation/cubit/profile_overview_cubit.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../domain/leaderboard.model.dart';
import '../../domain/medals.model.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.competitionId,
    required this.leaderboard,
    required this.isMe,
    required this.myPlayerId,
    required this.seasonLength,
    this.medals,
  });

  final String competitionId;
  final Leaderboard leaderboard;
  final bool isMe;
  final String? myPlayerId;
  final SeasonLength seasonLength;
  final Medals? medals;

  void _openProfile(BuildContext context) => showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<ProfileOverviewCubit>(
        param1: competitionId,
        param2: leaderboard.playerId,
      )..load(viewerPlayerId: myPlayerId),
      child: ProfileSheet(
        displayName: leaderboard.displayName,
        seasonLength: seasonLength,
        myPlayerId: myPlayerId,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasStreak =
        leaderboard.streakType == StreakType.win &&
        leaderboard.streakType.tier(leaderboard.streakCount) > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AdaptiveTappable(
        onTap: () => _openProfile(context),
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: isMe
                ? AdaptiveColors.accent(
                    context,
                  ).withValues(alpha: AppOpacity.selectedFill)
                : AppColors.neutralSurface,
          ),
          child: Row(
            children: [
              _rank(),
              Expanded(child: _nameColumn(context)),
              const SizedBox(width: AppSpacing.sm),
              _ratingColumn(context, hasStreak),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rank() => SizedBox(
    width: 32,
    child: Text(
      '${leaderboard.rank}',
      style: AppTypography.bodyLarge.copyWith(
        fontWeight: FontWeight.w700,
        color: leaderboard.rank.rankColor ?? AppColors.neutral,
        fontFeatures: AppTypography.tabularFigures,
      ),
    ),
  );

  Widget _nameColumn(BuildContext context) {
    final hasMedals = medals != null && medals!.hasAny;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                leaderboard.displayName,
                style: AppTypography.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (leaderboard.isOwner) ...[
              const SizedBox(width: AppSpacing.xs),
              if (isMe)
                Tag.icon(AdaptiveGlyph.star, color: AppColors.gold)
              else
                Tag(context.l10n.playersOwner, color: AppColors.gold),
            ],
            if (isMe) ...[
              const SizedBox(width: AppSpacing.xs),
              Tag(
                context.l10n.playersYou,
                color: AdaptiveColors.accent(context),
              ),
            ],
          ],
        ),
        if (hasMedals) ...[
          const SizedBox(height: 2),
          Row(children: _medalChips(medals!)),
        ],
      ],
    );
  }

  Widget _ratingColumn(BuildContext context, bool hasStreak) {
    final medal = leaderboard.medal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (medal != null) ...[
              AdaptiveIcon(AdaptiveGlyph.medal, color: medal.color, size: 16),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              leaderboard.rating.ratingLabel,
              style: AppTypography.titleSmall.copyWith(
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ],
        ),
        if (hasStreak || leaderboard.todayDelta != 0) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasStreak) ...[
                _streakBadge(context),
                if (leaderboard.todayDelta != 0)
                  const SizedBox(width: AppSpacing.xs),
              ],
              if (leaderboard.todayDelta != 0)
                TodayDeltaBadge(delta: leaderboard.todayDelta),
            ],
          ),
        ],
      ],
    );
  }

  Widget _streakBadge(BuildContext context) {
    final tier = leaderboard.streakType.tier(leaderboard.streakCount);

    return Semantics(
      label: context.l10n.profileStreakWin(leaderboard.streakCount),
      child: ExcludeSemantics(
        child: Container(
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
              for (var i = 0; i < tier; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                AdaptiveIcon(
                  AdaptiveGlyph.fire,
                  color: AppColors.fireCore,
                  size: 13,
                ),
              ],
            ],
          ),
        ),
      ),
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
}
