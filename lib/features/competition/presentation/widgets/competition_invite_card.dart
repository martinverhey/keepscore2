import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/tag.dart';
import '../../domain/competition.model.dart';
import 'join_code_tag.dart';
import 'join_qr_image.dart';

class CompetitionInviteCard extends StatelessWidget {
  static const double _qrSize = 200;
  static const double _codeWidth = _qrSize + AppSpacing.sm * 2;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.lg),
  );

  const CompetitionInviteCard({super.key, required this.overview});

  final CompetitionOverview overview;

  @override
  Widget build(BuildContext context) {
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
        Text(
          overview.competition.name,
          style: AppTypography.headlineMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${context.l10n.competitionPlayers(overview.playerCount)}'
          ' · ${context.l10n.competitionMatches(overview.matchCount)}',
          style: AppTypography.caption,
        ),
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
}
