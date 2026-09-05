import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/competition.model.dart';
import 'join_code_tag.dart';
import 'join_qr_image.dart';

class ActiveCompetitionCard extends StatelessWidget {
  const ActiveCompetitionCard({
    super.key,
    required this.overview,
    this.onOpen,
    this.onManage,
  });

  final CompetitionOverview overview;
  final VoidCallback? onOpen;
  final VoidCallback? onManage;

  static const double _qrSize = 200;
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
          _qr(context),
          if (onManage != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _manageRow(context),
          ],
        ],
      ),
    );
  }

  Widget _identity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onOpen != null) _eyebrow(context),
        _name(),
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
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.competitionsActive,
            style: AppTypography.eyebrow.copyWith(
              letterSpacing: 0.8,
              color: AdaptiveColors.accent(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        JoinCodeTag(code: overview.competition.joinCode),
      ],
    );
  }

  Widget _name() {
    if (onOpen == null) return _nameWithCode();

    return Row(
      children: [
        Flexible(child: _nameText()),
        const SizedBox(width: AppSpacing.xs),
        const AdaptiveIcon(
          AdaptiveGlyph.chevronRight,
          color: AppColors.neutral,
          size: 18,
        ),
      ],
    );
  }

  Widget _nameWithCode() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _nameText()),
        const SizedBox(width: AppSpacing.sm),
        JoinCodeTag(code: overview.competition.joinCode),
      ],
    );
  }

  Widget _nameText() {
    return Text(
      overview.competition.name,
      style: AppTypography.headlineMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
