import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/sheet.dart';
import 'competition_action.enum.dart';

class CompetitionActionSheet extends StatelessWidget {
  const CompetitionActionSheet({
    super.key,
    required this.name,
    required this.isOwner,
  });
  final String name;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: name,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOwner) ...[
            AdaptiveButton(
              label: context.l10n.competitionRename,
              kind: AdaptiveButtonKind.tinted,
              onPressed: () =>
                  Navigator.of(context).pop(CompetitionAction.rename),
            ),
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: context.l10n.competitionDelete,
              kind: AdaptiveButtonKind.destructive,
              onPressed: () =>
                  Navigator.of(context).pop(CompetitionAction.delete),
            ),
          ] else
            AdaptiveButton(
              label: context.l10n.competitionLeave,
              kind: AdaptiveButtonKind.destructive,
              onPressed: () =>
                  Navigator.of(context).pop(CompetitionAction.leave),
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
