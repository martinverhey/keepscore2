import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/competition.model.dart';
import 'competition_actions.dart';
import 'join_code_tag.dart';
import 'join_qr_image.dart';

class ActiveCompetitionCard extends StatelessWidget {
  const ActiveCompetitionCard({
    super.key,
    required this.overview,
    this.onOpen,
    this.onEdit,
    this.onRename,
    this.onLeave,
    this.onDelete,
  });

  final CompetitionOverview overview;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onRename;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  static const double _qrSize = 200;
  static const double _codeWidth = _qrSize + AppSpacing.sm * 2;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.lg),
  );

  @override
  Widget build(BuildContext context) {
    final onOpen = this.onOpen;
    if (onOpen == null) return _card(context);

    return AdaptiveTappable(
      onTap: onOpen,
      borderRadius: _radius,
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: _radius,
        color: AdaptiveColors.modalSurface(context),
        border: Border.all(
          color: AppColors.neutral.withValues(alpha: AppOpacity.controlBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _identity(context),
          const SizedBox(height: AppSpacing.lg),
          _codeAndQr(),
        ],
      ),
    );
  }

  Widget _identity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _name(),
        if (onOpen != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _eyebrow(context),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${context.l10n.competitionPlayers(overview.playerCount)}'
          ' · ${context.l10n.competitionMatches(overview.matchCount)}',
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _eyebrow(BuildContext context) {
    return Text(
      context.l10n.competitionsActive,
      style: AppTypography.eyebrow.copyWith(
        letterSpacing: 0.8,
        color: AdaptiveColors.accent(context),
      ),
    );
  }

  Widget _name() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            overview.competition.name,
            style: AppTypography.headlineMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_actions().hasActions) _actions(),
      ],
    );
  }

  Widget _codeAndQr() {
    return Center(
      child: SizedBox(
        width: _codeWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            JoinCodeTag(
              code: overview.competition.joinCode,
              style: TagStyle.codeLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            JoinQrImage(code: overview.competition.joinCode, size: _qrSize),
          ],
        ),
      ),
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
}
