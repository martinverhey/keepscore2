import 'package:flutter/widgets.dart';

import '../core/widgets/adaptive/adaptive.dart';
import '../l10n/app_localizations.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: AppLocalizations.of(context).appTitle,
      body: const AdaptiveLoader(),
    );
  }
}
