import 'package:flutter/widgets.dart';

import '../../../../core/extensions/bracket.extension.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/bracket.model.dart';
import '../cubit/tournament_cubit.dart';

class TournamentCard extends StatelessWidget {
  const TournamentCard({super.key, required this.state, required this.onOpen});

  static const int _previewPairings = 3;

  final TournamentReady state;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _titleRow(context),
          const SizedBox(height: AppSpacing.sm),
          if (state.champion case final champion?)
            _championRow(context, champion)
          else
            _upNext(context),
        ],
      ),
    );
  }

  Widget _titleRow(BuildContext context) {
    return Row(
      children: [
        const AdaptiveIcon(
          AdaptiveGlyph.trophy,
          color: AppColors.gold,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(context.l10n.tournamentTitle, style: AppTypography.titleSmall),
        const SizedBox(width: AppSpacing.xs),
        Tag(_statusLabel(context), color: _statusColor(context)),
        const Spacer(),
        const AdaptiveIcon(
          AdaptiveGlyph.chevronRight,
          color: AppColors.neutral,
          size: 18,
        ),
      ],
    );
  }

  String _statusLabel(BuildContext context) => state.isCompleted
      ? context.l10n.tournamentChampion
      : context.l10n.tournamentInProgress;

  Color _statusColor(BuildContext context) =>
      state.isCompleted ? AppColors.gold : AdaptiveColors.accent(context);

  Widget _championRow(BuildContext context, TournamentEntrant champion) {
    return Text(
      champion.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyLarge,
    );
  }

  Widget _upNext(BuildContext context) {
    final pairings = state.bracket.currentRound
        .where((match) => match.isPlayable && !match.isPlayed)
        .take(_previewPairings)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.bracket.roundLabel(context, state.bracket.currentRoundNumber),
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
