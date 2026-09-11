import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class PlannedMatchCard extends StatelessWidget {
  const PlannedMatchCard({
    super.key,
    required this.playerAName,
    required this.playerBName,
    required this.onTap,
    required this.onRemove,
  });

  final String playerAName;
  final String playerBName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.neutral.withValues(alpha: AppOpacity.cardFillFaint),
        border: Border.all(
          color: AppColors.neutral.withValues(alpha: AppOpacity.controlBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _name(playerAName, alignEnd: false)),
          _versus(context),
          Expanded(child: _name(playerBName, alignEnd: true)),
          const SizedBox(width: AppSpacing.xs),
          _removeButton(context),
        ],
      ),
    );
  }

  Widget _name(String name, {required bool alignEnd}) {
    return Text(
      name,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.neutral,
      ),
    );
  }

  Widget _versus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        context.l10n.matchesPrePickedVersus,
        style: AppTypography.captionSmall,
      ),
    );
  }

  Widget _removeButton(BuildContext context) {
    return AdaptiveIconButton(
      glyph: AdaptiveGlyph.delete,
      compact: true,
      semanticLabel: context.l10n.matchesPrePickedRemove,
      onPressed: onRemove,
    );
  }
}
