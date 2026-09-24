import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../extensions/build_context.extension.dart';
import '../../theme/app_tokens.dart';
import 'adaptive_colors.dart';
import 'adaptive_icon.dart';
import 'adaptive_menu_item.dart';
import 'app_platform.dart';

export 'adaptive_menu_item.dart';

class AdaptiveMenuButton extends StatelessWidget {
  const AdaptiveMenuButton({
    super.key,
    required this.items,
    required this.semanticLabel,
  });

  final List<AdaptiveMenuItem> items;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppPlatform.useCupertino ? _cupertino(context) : _material(context);
  }

  Widget _cupertino(BuildContext context) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.more,
      semanticLabel: semanticLabel,
      onPressed: () => _showActionSheet(context),
    );
  }

  Future<void> _showActionSheet(BuildContext context) async {
    final selected = await showCupertinoModalPopup<AdaptiveMenuItem>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          for (final item in items)
            CupertinoActionSheetAction(
              isDestructiveAction: item.destructive,
              onPressed: () => Navigator.of(sheetContext).pop(item),
              child: Text(item.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(context.l10n.commonCancel),
        ),
      ),
    );
    selected?.onSelected();
  }

  Widget _material(BuildContext context) {
    return PopupMenuButton<AdaptiveMenuItem>(
      tooltip: semanticLabel,
      icon: const AdaptiveIcon(AdaptiveGlyph.more),
      onSelected: (item) => item.onSelected(),
      itemBuilder: (menuContext) => [
        for (final item in items)
          PopupMenuItem(value: item, child: _materialItem(menuContext, item)),
      ],
    );
  }

  Widget _materialItem(BuildContext context, AdaptiveMenuItem item) {
    final color = item.destructive ? AdaptiveColors.destructive(context) : null;
    return Row(
      children: [
        AdaptiveIcon(item.glyph, color: color),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            item.label,
            style: AppTypography.bodyMedium.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
