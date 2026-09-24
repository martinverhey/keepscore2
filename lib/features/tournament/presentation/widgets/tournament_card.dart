import 'package:flutter/widgets.dart';

import '../../../../core/extensions/bracket.extension.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/bracket.model.dart';
import '../../domain/tournament_run.model.dart';

class TournamentCard extends StatelessWidget {
  const TournamentCard({super.key, required this.run, required this.onOpen});

  static const int _previewPairings = 3;

  final TournamentRun run;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTappable(
      onTap: onOpen,
      borderRadius: AppRadius.card,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutralSurface,
      ),
      child: Row(
        children: [
          Expanded(child: _details(context)),
          const SizedBox(width: AppSpacing.sm),
          const AdaptiveIcon(
            AdaptiveGlyph.chevronRight,
            color: AppColors.neutral,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _titleRow(context),
        const SizedBox(height: AppSpacing.sm),
        if (run.champion case final champion?)
          _championRow(context, champion)
        else
          _upNext(context),
      ],
    );
  }

  Widget _titleRow(BuildContext context) {
    return Row(
      children: [
        Text(context.l10n.tournamentTitle, style: AppTypography.titleSmall),
        if (!run.isCompleted) ...[
          const SizedBox(width: AppSpacing.xs),
          Tag(
            context.l10n.tournamentInProgress,
            color: AdaptiveColors.accent(context),
          ),
        ],
      ],
    );
  }

  Widget _championRow(BuildContext context, TournamentEntrant champion) {
    return Row(
      children: [
        const AdaptiveIcon(
          AdaptiveGlyph.trophy,
          color: AppColors.gold,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            champion.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Tag(context.l10n.tournamentChampion, color: AppColors.gold),
      ],
    );
  }

  Widget _upNext(BuildContext context) {
    final pairings = run.bracket.currentRound
        .where((match) => match.isPlayable && !match.isPlayed)
        .take(_previewPairings)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          run.bracket.roundLabel(context, run.bracket.currentRoundNumber),
          style: AppTypography.captionStrong,
        ),
        for (final match in pairings) ...[
          const SizedBox(height: 2),
          _pairing(match),
        ],
      ],
    );
  }

  Widget _pairing(TournamentMatch match) {
    return Row(
      children: [
        Expanded(child: _name(match.playerA, TextAlign.start)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('–', style: AppTypography.captionSmall),
        ),
        Expanded(child: _name(match.playerB, TextAlign.end)),
      ],
    );
  }

  Widget _name(TournamentEntrant? entrant, TextAlign align) {
    return Text(
      entrant?.displayName ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: AppTypography.bodySmall,
    );
  }
}
