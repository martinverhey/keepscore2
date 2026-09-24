import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/competition.model.dart';
import '../pages/invite_sheet.dart';
import 'competition_actions.dart';
import 'join_code_tag.dart';

class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.overview,
    required this.onTap,
    this.onEdit,
    this.onRename,
    this.onLeave,
    this.onDelete,
  });

  final CompetitionOverview overview;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onRename;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

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
            _header(competition),
            const SizedBox(height: AppSpacing.xs),
            _statsRow(context),
          ],
        ),
      ),
    );
  }

  Widget _header(Competition competition) {
    return Row(
      children: [
        Expanded(child: _name(competition)),
        const SizedBox(width: AppSpacing.xs),
        JoinCodeTag(code: competition.joinCode),
      ],
    );
  }

  Widget _name(Competition competition) {
    return Text(
      competition.name,
      style: AppTypography.titleSmall,
      overflow: TextOverflow.ellipsis,
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
        _inviteButton(context),
        if (_actions().hasActions) _actions(),
      ],
    );
  }

  CompetitionActions _actions() {
    return CompetitionActions(
      onEdit: onEdit,
      onRename: onRename,
      onLeave: onLeave,
      onDelete: onDelete,
    );
  }

  Widget _inviteButton(BuildContext context) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.invite,
      semanticLabel: context.l10n.competitionInviteAction,
      onPressed: () => showInviteSheet(context, overview: overview),
    );
  }
}
