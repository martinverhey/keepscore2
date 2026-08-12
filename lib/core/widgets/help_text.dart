import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

class HelpText extends StatelessWidget {
  const HelpText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.neutral, fontSize: 13),
    );
  }
}
