import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../../core/widgets/tag.dart';
import '../../../competition/domain/competition.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/widgets/profile_sheet.dart';
import '../../domain/leaderboard.dart';
import '../../domain/medal_tally.dart';
import 'streak_row_glow.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.competitionId,
    required this.standing,
    required this.isMe,
    required this.myPlayerId,
    required this.seasonLength,
    this.medals,
  });

  final String competitionId;
  final Leaderboard standing;
  final bool isMe;
  final String? myPlayerId;
  final SeasonLength seasonLength;
  final MedalTally? medals;

  Color? get _rankColor => switch (standing.rank) {
    1 => AppColors.gold,
    2 => AppColors.silver,
    3 => AppColors.bronze,
    _ => null,
  };

  void _openProfile(BuildContext context) => showAdaptiveSheet<void>(
    context,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<ProfileCubit>(param1: competitionId, param2: standing.playerId)
            ..load(viewerPlayerId: myPlayerId),
      child: ProfileSheet(
        displayName: standing.displayName,
        seasonLength: seasonLength,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final badges = [
      if (isMe) context.l10n.playersYou,
      if (!standing.isClaimed) context.l10n.playersUnclaimed,
    ];
    final hasStreak = isRowStreak(standing.streakType, standing.streakCount);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openProfile(context),
        child: StreakRowGlow(
          type: standing.streakType,
          count: standing.streakCount,
          fallbackColor: isMe
              ? AdaptiveColors.accent(context).withValues(alpha: 0.12)
              : AppColors.neutral.withValues(alpha: 0.08),
          borderRadius: AppRadius.card,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _rank(),
              Expanded(flex: 3, child: _nameColumn(badges)),
              Expanded(flex: 2, child: Center(child: _winRate(context))),
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
      '${standing.rank}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _rankColor ?? AppColors.neutral,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );

  Widget _nameColumn(List<String> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                standing.displayName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final badge in badges) ...[
              const SizedBox(width: AppSpacing.xs),
              Tag(badge, color: AppColors.neutral),
            ],
          ],
        ),
        if (medals != null && medals!.hasAny) ...[
          const SizedBox(height: 2),
          Row(children: _medalChips(medals!)),
        ],
      ],
    );
  }

  Widget _winRate(BuildContext context) {
    final unplayed = standing.played == 0;

    return Semantics(
      label: unplayed ? context.l10n.leaderboardUnplayed : null,
      child: ExcludeSemantics(
        excluding: unplayed,
        child: Text(
          unplayed
              ? '—'
              : context.l10n.leaderboardWinRate(
                  (standing.winRate * 100).round(),
                ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _ratingColumn(BuildContext context, bool hasStreak) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatRating(standing.rating),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (hasStreak) ...[
          const SizedBox(height: 2),
          _streakBadge(context),
        ],
      ],
    );
  }

  Widget _streakBadge(BuildContext context) {
    final isWin = standing.streakType == StreakType.win;
    final color = streakCoreColor(standing.streakType);

    return Semantics(
      label: isWin
          ? context.l10n.profileStreakWin(standing.streakCount)
          : context.l10n.profileStreakLoss(standing.streakCount),
      child: ExcludeSemantics(
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
              '${standing.streakCount}',
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
    );
  }

  List<Widget> _medalChips(MedalTally medals) {
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
