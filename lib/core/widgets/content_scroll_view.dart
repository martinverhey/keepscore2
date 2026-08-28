import 'package:flutter/widgets.dart';

import '../extensions/box_constraints.extension.dart';
import '../theme/app_tokens.dart';

class ContentScrollView extends StatelessWidget {
  const ContentScrollView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              constraints.contentHorizontalInset,
              AppSpacing.sm,
              constraints.contentHorizontalInset,
              AppSpacing.xl,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
