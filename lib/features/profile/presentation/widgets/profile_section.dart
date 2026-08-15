import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/medal_chip.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../../competition/domain/competition.dart';
import '../../../leaderboard/domain/leaderboard.dart';
import '../../../leaderboard/domain/medal_tally.dart';
import '../cubit/profile_cubit.dart';
import 'initials_circle.dart';
import 'profile_sheet.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.competitionId,
    required this.playerId,
    required this.displayName,
    required this.seasonLength,
    required this.playerCount,
    this.standing,
    this.medals,
  });

  final String competitionId;
  final String playerId;
  final String displayName;
  final SeasonLength seasonLength;
  final int playerCount;
  final Leaderboard? standing;
  final MedalTally? medals;

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.accent(context);
    final s = standing;
    final hasStats = s != null && s.played > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showAdaptiveSheet<void>(
        context,
        builder: (_) => BlocProvider(
          create: (_) =>
              getIt<ProfileCubit>(param1: competitionId, param2: playerId)
                ..load(viewerPlayerId: playerId),
          child: ProfileSheet(
            displayName: displayName,
            seasonLength: seasonLength,
            medals: medals,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: AppRadius.card,
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, s),
            if (hasStats) ...[
              const SizedBox(height: AppSpacing.md),
              _statRow(context, s),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Leaderboard? s) {
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (s != null && s.played > 0) ...[
                const SizedBox(height: 2),
                _rankAndMedalsRow(context, s),
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

  Widget _rankAndMedalsRow(BuildContext context, Leaderboard s) {
    final tally = medals;

    return Row(
      children: [
        Flexible(
          child: Text(
            context.l10n.profileRank(s.rank, playerCount),
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

  Widget _medalRow(MedalTally medals) {
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

  List<Widget> _medalChips(MedalTally medals) {
    final chips = [
      if (medals.gold > 0) MedalChip(color: AppColors.gold, count: medals.gold),
      if (medals.silver > 0)
        MedalChip(color: AppColors.silver, count: medals.silver),
      if (medals.bronze > 0)
        MedalChip(color: AppColors.bronze, count: medals.bronze),
    ];
    return chips;
  }

  Widget _statRow(BuildContext context, Leaderboard s) {
    final winRatePercent = s.played == 0 ? 0 : (s.winRate * 100).round();

    return Row(
      children: [
        _statBlock(
          formatRating(s.rating),
          context.l10n.profileSeasonRatingLabel,
        ),
        _statBlock('$winRatePercent%', context.l10n.profileWinRateLabel),
        _statBlock('${s.played}', context.l10n.profileSeasonGamesLabel),
      ],
    );
  }

  Widget _statBlock(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
}
