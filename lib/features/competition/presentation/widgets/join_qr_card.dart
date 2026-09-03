import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import 'join_qr_image.dart';

class JoinQrCard extends StatelessWidget {
  const JoinQrCard({super.key, required this.code});
  final String code;

  static const double _qrSize = 168;

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.accent(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: accent.withValues(alpha: AppOpacity.accentFill),
        border: Border.all(
          color: accent.withValues(alpha: AppOpacity.accentBorder),
        ),
      ),
      child: Column(
        children: [
          JoinQrImage(code: code, size: _qrSize),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.competitionQrInvite,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.competitionQrHelp,
            textAlign: TextAlign.center,
            style: AppTypography.captionSmall,
          ),
        ],
      ),
    );
  }
}
