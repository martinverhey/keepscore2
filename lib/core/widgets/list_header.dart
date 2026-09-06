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
      verticalDirection: VerticalDirection.up,
      children: [
        if (subtitle case final subtitle?) ...[
          Text(subtitle, style: AppTypography.captionSmall),
          const SizedBox(height: 2),
        ],
        Text(title, style: AppTypography.titleSmall),
      ],
    );
  }
}
