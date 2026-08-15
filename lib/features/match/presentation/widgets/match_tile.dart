import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../domain/match_entry.model.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    required this.onTap,
    this.myPlayerId,
  });

  final MatchEntry match;
  final VoidCallback onTap;
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
    final rail = BorderSide(color: AdaptiveColors.accent(context), width: 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: AppColors.neutral.withValues(alpha: 0.08),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(child: _side(team: MatchTeam.b)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _side({required MatchTeam team}) {
    final roster = match.roster(team);
    final won = match.winner == team;
    final alignEnd = team == MatchTeam.b;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in roster)
          Text(
            entry.displayName,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: won ? FontWeight.w700 : FontWeight.w500,
              color: won ? null : AppColors.neutral,
            ),
          ),
        const SizedBox(height: 2),
        RatingDelta(
          value: roster.isEmpty ? 0 : roster.first.ratingDelta,
          fontSize: 13,
        ),
      ],
    );
  }
}
