import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/competition.model.dart';
import '../pages/invite_sheet.dart';
import 'join_code_tag.dart';

class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
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
          color: AppColors.neutralSurface,
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
            style: AppTypography.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AdaptiveIconButton(
          glyph: AdaptiveGlyph.invite,
          semanticLabel: context.l10n.competitionInviteAction,
          onPressed: () => showInviteSheet(context, overview: overview),
        ),
        const SizedBox(width: AppSpacing.xs),
        JoinCodeTag(code: competition.joinCode),
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
            style: AppTypography.caption,
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
