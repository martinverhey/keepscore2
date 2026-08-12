import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
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
    return Sheet(
      title: context.l10n.competitionInviteTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JoinQrCard(code: code),
          const SizedBox(height: AppSpacing.sm),
          JoinCodeCard(code: code),
        ],
      ),
    );
  }
}
