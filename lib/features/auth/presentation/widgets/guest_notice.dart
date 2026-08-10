import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';

class GuestNotice extends StatelessWidget {
  const GuestNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutral.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              color: AppColors.neutral.withValues(alpha: 0.16),
            ),
            child: Text(
              l10n.authGuestBadge,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(color: AppColors.neutral, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: l10n.authUpgradeTitle,
            kind: AdaptiveButtonKind.tinted,
            expand: false,
            onPressed: () => context.push(Routes.upgradeAccount),
          ),
        ],
      ),
    );
  }
}
