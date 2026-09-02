import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTypography.titleSmall),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.captionSmall),
        ],
      ],
    );
  }
}
