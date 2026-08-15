import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/tag.dart';
import '../../../../core/widgets/today_delta_badge.dart';
import '../../../competition/domain/competition.model.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
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

  Color? get _rankColor => switch (leaderboard.rank) {
    1 => AppColors.gold,
    2 => AppColors.silver,
    3 => AppColors.bronze,
    _ => null,
  };

  void _openProfile(BuildContext context) => showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<ProfileCubit>(
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
        leaderboard.streakCount >= 2 &&
        leaderboard.streakType != StreakType.none;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openProfile(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: isMe
                ? AdaptiveColors.accent(context).withValues(alpha: 0.12)
                : AppColors.neutral.withValues(alpha: 0.08),
          ),
          child: Row(
            children: [
              _rank(),
              Expanded(child: _nameColumn(context, hasStreak)),
              const SizedBox(width: AppSpacing.sm),
              _ratingColumn(context),
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
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _rankColor ?? AppColors.neutral,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );

  Widget _nameColumn(BuildContext context, bool hasStreak) {
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (leaderboard.isOwner) ...[
              const SizedBox(width: AppSpacing.xs),
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
        if (hasMedals || hasStreak) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              if (hasMedals) ..._medalChips(medals!),
              if (hasStreak) ...[
                const Spacer(),
                _streakBadge(context),
                const Spacer(),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _ratingColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
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
          const SizedBox(height: 2),
          TodayDeltaBadge(delta: leaderboard.todayDelta),
        ],
      ],
    );
  }

  Widget _streakBadge(BuildContext context) {
    final isWin = leaderboard.streakType == StreakType.win;
    final color = isWin ? AppColors.fireCore : AppColors.iceCore;

    return Semantics(
      label: isWin
          ? context.l10n.profileStreakWin(leaderboard.streakCount)
          : context.l10n.profileStreakLoss(leaderboard.streakCount),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            color: color.withValues(alpha: 0.16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdaptiveIcon(
                isWin ? AdaptiveGlyph.fire : AdaptiveGlyph.ice,
                color: color,
                size: 13,
              ),
              const SizedBox(width: 2),
              Text(
                '${leaderboard.streakCount}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
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
