import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/hint_card.dart';
import '../../../../core/widgets/tag.dart';

class GuestNotice extends StatelessWidget {
  const GuestNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return HintCard(
      badge: Tag(context.l10n.authGuestBadge, color: AppColors.neutral),
      message: message,
      actionLabel: context.l10n.authUpgradeTitle,
      onAction: () => context.push(Routes.upgradeAccount),
    );
  }
}
