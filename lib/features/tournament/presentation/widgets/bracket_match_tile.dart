import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/bracket.model.dart';

class BracketMatchTile extends StatelessWidget {
  const BracketMatchTile({
    super.key,
    required this.match,
    required this.width,
    required this.height,
    this.onTap,
  });

  final TournamentMatch match;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;

    return SizedBox(
      width: width,
      height: height,
      child: tap == null
          ? _card(context)
          : AdaptiveTappable(
              onTap: tap,
              borderRadius: AppRadius.card,
              child: _card(context),
            ),
    );
  }

  Widget _card(BuildContext context) {
    final accent = AdaptiveColors.accent(context);
    final isNext = onTap != null && !match.isPlayed;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: isNext
            ? accent.withValues(alpha: AppOpacity.selectedFill)
            : AppColors.neutralSurface,
        border: Border.all(
          color: isNext ? accent : AppColors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _side(context, match.playerA, match.scoreA),
          const SizedBox(height: 2),
          _side(context, match.playerB, match.scoreB),
        ],
      ),
    );
  }

  Widget _side(BuildContext context, TournamentEntrant? entrant, int? score) {
    if (entrant == null) return _placeholder(context);

    final won = match.isWinner(entrant);

    return Row(
      children: [
        Expanded(
          child: Text(
            entrant.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: won ? FontWeight.w700 : FontWeight.w400,
              color: won ? AdaptiveColors.accent(context) : null,
            ),
          ),
        ),
        if (score != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$score',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: won ? FontWeight.w700 : FontWeight.w400,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        match.isBye
            ? context.l10n.tournamentBye
            : context.l10n.tournamentWaiting,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.captionSmall,
      ),
    );
  }
}
