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
      child: IntrinsicHeight(child: _teams(context)),
    );
  }

  Widget _teams(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      children: [
        Expanded(
          child: _names(context, team: team, alignEnd: alignEnd),
        ),
        const SizedBox(height: 2),
        _delta(team),
      ],
    );
  }

  Widget _names(
    BuildContext context, {
    required MatchTeam team,
    required bool alignEnd,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${match.teamAScore}', style: scoreStyle),
            _separator(),
            Text('${match.teamBScore}', style: scoreStyle),
          ],
        ),
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

  Widget _delta(MatchTeam team) {
    final players = match.players(team);

    return RatingDelta(
      value: players.isEmpty ? 0 : players.first.ratingDelta,
      fontSize: AppTypography.labelLargeSize,
    );
  }
}
