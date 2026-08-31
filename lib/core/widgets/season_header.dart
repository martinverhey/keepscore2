import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

class SeasonHeader extends StatelessWidget {
  const SeasonHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTypography.titleSmall),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTypography.captionSmall),
      ],
    );
  }
}
