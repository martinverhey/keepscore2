import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../domain/match_entry.model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.myPlayerId,
  });

  final MatchEntry match;
  final VoidCallback? onTap;
  final String? myPlayerId;

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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutralSurface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_teams(context), const SizedBox(height: 2), _deltas()],
      ),
    );
  }

  Widget _teams(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _side(context, team: MatchTeam.a)),
        _score(),
        Expanded(child: _side(context, team: MatchTeam.b)),
      ],
    );
  }

  Widget _side(BuildContext context, {required MatchTeam team}) {
    final alignEnd = team == MatchTeam.b;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in match.players(team))
          Text(
            entry.displayName,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: entry.playerId == myPlayerId
                  ? AdaptiveColors.accent(context)
                  : AppColors.neutral,
            ),
          ),
      ],
    );
  }

  Widget _score() {
    final scoreStyle = AppTypography.headlineMedium.copyWith(
      fontFeatures: AppTypography.tabularFigures,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${match.teamAScore}', style: scoreStyle),
          _separator(),
          Text('${match.teamBScore}', style: scoreStyle),
        ],
      ),
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        '–',
        style: AppTypography.bodySmall.copyWith(color: AppColors.neutralSoft),
      ),
    );
  }

  Widget _deltas() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_delta(MatchTeam.a), _delta(MatchTeam.b)],
    );
  }

  Widget _delta(MatchTeam team) {
    final players = match.players(team);

    return RatingDelta(
      value: players.isEmpty ? 0 : players.first.ratingDelta,
      fontSize: AppTypography.labelLargeSize,
    );
  }
}
