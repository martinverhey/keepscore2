import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/competition.model.dart';
import 'invite_sheet.dart';

class CompetitionTile extends StatelessWidget {
  const CompetitionTile({
    super.key,
    required this.overview,
    required this.onTap,
    this.onManage,
  });

  final CompetitionOverview overview;
  final VoidCallback onTap;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final competition = overview.competition;

    return AdaptiveTappable(
      onTap: onTap,
      borderRadius: AppRadius.card,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: AppColors.neutral.withValues(alpha: 0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, competition),
            const SizedBox(height: AppSpacing.xs),
            _statsRow(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Competition competition) {
    return Row(
      children: [
        Expanded(
          child: Text(
            competition.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AdaptiveIconButton(
          glyph: AdaptiveGlyph.invite,
          semanticLabel: context.l10n.competitionInviteAction,
          onPressed: () => showInviteSheet(context, code: competition.joinCode),
        ),
        const SizedBox(width: AppSpacing.xs),
        Tag(
          competition.joinCode,
          color: AdaptiveColors.accent(context),
          style: TagStyle.code,
        ),
      ],
    );
  }

  Widget _statsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${context.l10n.competitionPlayers(overview.playerCount)}'
            ' · ${context.l10n.competitionMatches(overview.matchCount)}',
            style: const TextStyle(color: AppColors.neutral, fontSize: 13),
          ),
        ),
        if (onManage != null)
          AdaptiveButton(
            label: context.l10n.competitionManage,
            kind: AdaptiveButtonKind.plain,
            expand: false,
            onPressed: onManage,
          ),
      ],
    );
  }
}
