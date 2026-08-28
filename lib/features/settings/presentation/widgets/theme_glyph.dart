import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/theme_preference.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/theme_preference.enum.dart';

class ThemeGlyph extends StatelessWidget {
  const ThemeGlyph({
    super.key,
    required this.preference,
    this.size = AppTypography.bodyLargeSize,
  });

  final ThemePreference preference;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: preference.label(context.l10n),
      child: AdaptiveIcon(
        preference.glyph,
        size: size,
        color: AdaptiveColors.accent(context),
      ),
    );
  }
}
