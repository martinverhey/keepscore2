import 'package:flutter/widgets.dart';

import '../core/extensions/build_context.extension.dart';
import '../core/widgets/adaptive/adaptive.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: context.l10n.appTitle,
      body: const AdaptiveLoader(),
    );
  }
}
