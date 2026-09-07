import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class CompetitionActions extends StatelessWidget {
  const CompetitionActions({
    super.key,
    this.onRename,
    this.onLeave,
    this.onDelete,
    this.compact = false,
  });

  final VoidCallback? onRename;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRename != null)
          AdaptiveIconButton(
            glyph: AdaptiveGlyph.rename,
            semanticLabel: context.l10n.competitionRename,
            compact: compact,
            onPressed: onRename,
          ),
        if (onLeave != null)
          AdaptiveIconButton(
            glyph: AdaptiveGlyph.leave,
            semanticLabel: context.l10n.competitionLeave,
            destructive: true,
            compact: compact,
            onPressed: onLeave,
          ),
        if (onDelete != null)
          AdaptiveIconButton(
            glyph: AdaptiveGlyph.delete,
            semanticLabel: context.l10n.competitionDelete,
            destructive: true,
            compact: compact,
            onPressed: onDelete,
          ),
      ],
    );
  }
}
