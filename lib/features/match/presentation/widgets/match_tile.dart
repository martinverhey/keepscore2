import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/rating_delta.dart';
import '../../domain/match_entry.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.match, required this.onTap});

  final MatchEntry match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md - 4,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: AppColors.neutral.withValues(alpha: 0.08),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _Side(match: match, team: MatchTeam.a),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      '${match.teamAScore} – ${match.teamBScore}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _Side(match: match, team: MatchTeam.b),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat.MMMd(locale).add_Hm().format(match.playedAt),
                style: const TextStyle(color: AppColors.neutral, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.match, required this.team});

  final MatchEntry match;
  final MatchTeam team;

  @override
  Widget build(BuildContext context) {
    final roster = match.roster(team);
    final won = match.winner == team;
    final alignEnd = team == MatchTeam.b;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          roster.map((entry) => entry.displayName).join(' & '),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
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
