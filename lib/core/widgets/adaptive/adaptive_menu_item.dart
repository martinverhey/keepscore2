import 'package:flutter/widgets.dart';

import 'adaptive_glyph.enum.dart';

class AdaptiveMenuItem {
  const AdaptiveMenuItem({
    required this.label,
    required this.glyph,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final AdaptiveGlyph glyph;
  final VoidCallback onSelected;
  final bool destructive;
}
