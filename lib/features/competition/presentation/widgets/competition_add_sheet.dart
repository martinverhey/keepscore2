import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import 'competition_add_action.enum.dart';

class CompetitionAddSheet extends StatelessWidget {
  const CompetitionAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.competitionsAdd,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveButton(
            label: context.l10n.competitionsCreate,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () =>
                Navigator.of(context).pop(CompetitionAddAction.create),
          ),
          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: context.l10n.competitionsJoin,
            kind: AdaptiveButtonKind.tinted,
            onPressed: () =>
                Navigator.of(context).pop(CompetitionAddAction.join),
          ),
        ],
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
