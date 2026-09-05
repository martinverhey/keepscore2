import 'package:flutter/widgets.dart';

import '../error/failure.dart';
import '../error/failure_messages.dart';
import '../extensions/build_context.extension.dart';
import '../theme/app_tokens.dart';

class FailureText extends StatelessWidget {
  const FailureText(this.failure, {super.key});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        failure.localized(context.l10n),
        style: const TextStyle(color: AppColors.negative),
      ),
    );
  }
}
