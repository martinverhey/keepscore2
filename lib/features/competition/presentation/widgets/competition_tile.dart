import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/competition.dart';

class CompetitionTile extends StatelessWidget {
  const CompetitionTile({
    super.key,
    required this.overview,
    required this.onTap,
  });

  final CompetitionOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final competition = overview.competition;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: AppColors.neutral.withValues(alpha: 0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    competition.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _CodeChip(code: competition.joinCode),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.competitionPlayers(overview.playerCount)}'
              ' · ${l10n.competitionMatches(overview.matchCount)}',
              style: const TextStyle(color: AppColors.neutral, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: AdaptiveColors.accent(context).withValues(alpha: 0.14),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AdaptiveColors.accent(context),
        ),
      ),
    );
  }
}
