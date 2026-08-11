import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import 'join_code_card.dart';
import 'join_qr_card.dart';

Future<void> showInviteSheet(BuildContext context, {required String code}) {
  return showAdaptiveSheet<void>(
    context,
    builder: (_) => _InviteSheet(code: code),
  );
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.competitionInviteTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          JoinQrCard(code: code),
          const SizedBox(height: AppSpacing.sm),
          JoinCodeCard(code: code),
        ],
      ),
    );
  }
}
