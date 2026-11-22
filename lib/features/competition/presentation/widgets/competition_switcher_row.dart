import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/date_time.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/competition.model.dart';
import 'competition_actions.dart';

class CompetitionSwitcherRow extends StatelessWidget {
  const CompetitionSwitcherRow({
    super.key,
    required this.overview,
    required this.isCurrent,
    required this.isOwner,
    required this.onTap,
    this.actions,
  });

  final CompetitionOverview overview;
  final bool isCurrent;
  final bool isOwner;
  final VoidCallback onTap;
  final CompetitionActions? actions;

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.accent(context);

    return Semantics(
      selected: isCurrent,
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: isCurrent
                ? accent.withValues(alpha: AppOpacity.selectedFill)
                : AppColors.neutralSurface,
          ),
          child: Row(
            children: [
              Expanded(child: _details(context)),
              if (actions case final actions? when actions.hasActions) actions,
            ],
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _nameRow(context),
        const SizedBox(height: AppSpacing.xs),
        Text(_lastPlayed(context), style: AppTypography.caption),
      ],
    );
  }

  Widget _nameRow(BuildContext context) {
    final color = isCurrent ? AdaptiveColors.accent(context) : null;
    return Row(
      children: [
        Flexible(
          child: Text(
            overview.competition.name,
            style: AppTypography.titleSmall.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOwner) ...[
          const SizedBox(width: AppSpacing.xs),
          Tag(context.l10n.playersOwner, color: AppColors.gold),
        ],
      ],
    );
  }

  String _lastPlayed(BuildContext context) {
    return switch (overview.lastPlayedAt) {
      final playedAt? => playedAt.lastPlayedLabel(context),
      null => context.l10n.competitionNotPlayed,
    };
  }
}
