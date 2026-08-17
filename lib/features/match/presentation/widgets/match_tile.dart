import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../domain/match_entry.model.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    this.onTap,
    this.myPlayerId,
  });

  final MatchEntry match;
  final VoidCallback? onTap;
  final String? myPlayerId;

  MatchTeam? get _myTeam {
    if (myPlayerId == null) return null;
    if (match.teamA.any((entry) => entry.playerId == myPlayerId)) {
      return MatchTeam.a;
    }
    if (match.teamB.any((entry) => entry.playerId == myPlayerId)) {
      return MatchTeam.b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: onTap == null
          ? _content(context)
          : AdaptiveTappable(
              onTap: onTap!,
              borderRadius: AppRadius.card,
              child: _content(context),
            ),
    );
  }

  Widget _content(BuildContext context) {
    final rail = BorderSide(color: AdaptiveColors.accent(context), width: 1);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutralSurface,
        border: switch (_myTeam) {
          MatchTeam.a => Border(left: rail),
          MatchTeam.b => Border(right: rail),
          null => null,
        },
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _side(team: MatchTeam.a)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '${match.teamAScore} – ${match.teamBScore}',
              style: AppTypography.titleMedium.copyWith(
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ),
          Expanded(child: _side(team: MatchTeam.b)),
        ],
      ),
    );
  }

  Widget _side({required MatchTeam team}) {
    final players = match.players(team);
    final won = match.winner == team;
    final alignEnd = team == MatchTeam.b;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in players)
          Text(
            entry.displayName,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: won ? FontWeight.w700 : FontWeight.w500,
              color: won ? null : AppColors.neutral,
            ),
          ),
        const SizedBox(height: 2),
        RatingDelta(
          value: players.isEmpty ? 0 : players.first.ratingDelta,
          fontSize: AppTypography.labelLargeSize,
        ),
      ],
    );
  }
}
