import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class CompetitionActions extends StatelessWidget {
  const CompetitionActions({
    super.key,
    this.onEdit,
    this.onRename,
    this.onLeave,
    this.onDelete,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onRename;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  bool get hasActions =>
      onEdit != null || onRename != null || onLeave != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    return AdaptiveMenuButton(
      semanticLabel: context.l10n.commonMoreActions,
      items: _items(context),
    );
  }

  List<AdaptiveMenuItem> _items(BuildContext context) {
    return [
      if (onEdit case final onEdit?)
        AdaptiveMenuItem(
          label: context.l10n.competitionEdit,
          glyph: AdaptiveGlyph.settings,
          onSelected: onEdit,
        ),
      if (onRename case final onRename?)
        AdaptiveMenuItem(
          label: context.l10n.competitionRename,
          glyph: AdaptiveGlyph.rename,
          onSelected: onRename,
        ),
      if (onLeave case final onLeave?)
        AdaptiveMenuItem(
          label: context.l10n.competitionLeave,
          glyph: AdaptiveGlyph.leave,
          destructive: true,
          onSelected: onLeave,
        ),
      if (onDelete case final onDelete?)
        AdaptiveMenuItem(
          label: context.l10n.competitionDelete,
          glyph: AdaptiveGlyph.delete,
          destructive: true,
          onSelected: onDelete,
        ),
    ];
  }
}
