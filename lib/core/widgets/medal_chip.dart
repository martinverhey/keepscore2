import 'package:flutter/widgets.dart';

import 'adaptive/adaptive.dart';

class MedalChip extends StatelessWidget {
  const MedalChip({super.key, required this.color, required this.count});

  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveIcon(AdaptiveGlyph.medal, color: color, size: 14),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
