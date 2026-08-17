import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';

class InitialsCircle extends StatelessWidget {
  const InitialsCircle({super.key, required this.displayName, this.size = 40});
  final String displayName;
  final double size;

  String get _initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    final letters = [
      for (final word in words)
        if (word.isNotEmpty) word[0].toUpperCase(),
    ];
    if (letters.isEmpty) return '?';
    return letters.length == 1
        ? letters.first
        : '${letters.first}${letters.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AdaptiveColors.accent(
          context,
        ).withValues(alpha: AppOpacity.badgeFill),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: AdaptiveColors.accent(context),
        ),
      ),
    );
  }
}
