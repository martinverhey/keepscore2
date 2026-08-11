import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';

class JoinQrCard extends StatelessWidget {
  const JoinQrCard({super.key, required this.code});
  final String code;

  static const double _qrSize = 168;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = AdaptiveColors.accent(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: SizedBox(
              width: _qrSize,
              height: _qrSize,
              child: QrImageView(
                data: code,
                size: _qrSize,
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFFFFFFFF),
                semanticsLabel: code,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.competitionQrInvite,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.competitionQrHelp,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.neutral, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
