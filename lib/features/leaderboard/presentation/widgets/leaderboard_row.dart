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
    this.opensProfile = true,
  });

  static const double _minHeight = 60;
  static const double _secondaryLineGap = 2;

  final String competitionId;
  final Leaderboard leaderboard;
  final bool isMe;
  final String? myPlayerId;
  final SeasonLength seasonLength;
  final Medals? medals;
  final bool opensProfile;

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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: opensProfile
          ? AdaptiveTappable(
              onTap: () => _openProfile(context),
              borderRadius: AppRadius.card,
              child: _card(context),
            )
          : _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
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
          _ratingColumn(context),
        ],
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

  Widget _nameColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: _secondaryLineGap,
    children: [_nameRow(context), ?_medalsRow()],
  );

  Widget _nameRow(BuildContext context) => Row(
    children: [
      Flexible(
        child: Text(
          leaderboard.displayName,
          style: AppTypography.bodyLarge.copyWith(
            color: isMe ? AdaptiveColors.accent(context) : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (leaderboard.isOwner) ...[
        const SizedBox(width: AppSpacing.xs),
        Tag(context.l10n.playersOwner, color: AppColors.gold),
      ],
    ],
  );

  Widget? _medalsRow() {
    final tally = medals;
    if (tally == null || !tally.hasAny) return null;

    return Row(children: _medalChips(tally));
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

  Widget _ratingColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    spacing: _secondaryLineGap,
    children: [_ratingRow(), ?_badgesRow(context)],
  );

  Widget _ratingRow() {
    final medal = leaderboard.medal;

    return Row(
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
    );
  }

  Widget? _badgesRow(BuildContext context) {
    final hasStreak =
        leaderboard.streakType == StreakType.win &&
        leaderboard.streakType.tier(leaderboard.streakCount) > 0;
    final hasTodayDelta = leaderboard.todayDelta != 0;
    if (!hasStreak && !hasTodayDelta) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasStreak) _streakBadge(context),
        if (hasStreak && hasTodayDelta) const SizedBox(width: AppSpacing.xs),
        if (hasTodayDelta) TodayDeltaBadge(delta: leaderboard.todayDelta),
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
            color: tier.flameBadgeFill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tier.flameCount; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                AdaptiveIcon(
                  AdaptiveGlyph.fire,
                  color: tier.flameColor,
                  size: 13,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
