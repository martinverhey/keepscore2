import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/competition.model.dart';
import 'join_qr_image.dart';

class ActiveCompetitionCard extends StatelessWidget {
  const ActiveCompetitionCard({
    super.key,
    required this.overview,
    required this.onOpen,
    this.onManage,
  });

  final CompetitionOverview overview;
  final VoidCallback onOpen;
  final VoidCallback? onManage;

  static const double _qrSize = 200;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.lg),
  );

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.accent(context);

    return AdaptiveTappable(
      onTap: onOpen,
      borderRadius: _radius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: _radius,
          color: AdaptiveColors.modalSurface(context),
          border: Border.all(
            color: AppColors.neutral.withValues(
              alpha: AppOpacity.controlBorder,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _identity(context, accent),
            const SizedBox(height: AppSpacing.lg),
            _qr(context),
            if (onManage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _manageRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _identity(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _eyebrow(context, accent),
        _name(context),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${context.l10n.competitionPlayers(overview.playerCount)}'
          ' · ${context.l10n.competitionMatches(overview.matchCount)}',
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _eyebrow(BuildContext context, Color accent) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.competitionsActive,
            style: AppTypography.eyebrow.copyWith(
              letterSpacing: 0.8,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Tag(overview.competition.joinCode, color: accent, style: TagStyle.code),
      ],
    );
  }

  Widget _name(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            overview.competition.name,
            style: AppTypography.headlineMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const AdaptiveIcon(
          AdaptiveGlyph.chevronRight,
          color: AppColors.neutral,
          size: 18,
        ),
      ],
    );
  }

  Widget _qr(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          JoinQrImage(code: overview.competition.joinCode, size: _qrSize),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.competitionQrScan,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _manageRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
