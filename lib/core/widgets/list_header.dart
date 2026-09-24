import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'adaptive/adaptive_icon.dart';
import 'adaptive/adaptive_tappable.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    if (onTap == null) return _block();

    return Semantics(
      button: true,
      label: semanticLabel,
      child: AdaptiveTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: _block(),
      ),
    );
  }

  Widget _block() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      verticalDirection: VerticalDirection.up,
      children: [
        if (subtitle case final subtitle?) ...[
          Text(subtitle, style: AppTypography.captionSmall),
          const SizedBox(height: 2),
        ],
        _title(),
      ],
    );
  }

  Widget _title() {
    if (onTap == null) return _titleText();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _titleText()),
        const SizedBox(width: AppSpacing.xs),
        const AdaptiveIcon(AdaptiveGlyph.chevronDown, size: 16),
      ],
    );
  }

  Widget _titleText() {
    return Text(title, style: AppTypography.titleSmall);
  }
}
