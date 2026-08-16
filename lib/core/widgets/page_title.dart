import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../extensions/build_context_l10n.dart';

void setPageTitle(BuildContext context, String label) {
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(
      label: '$label · ${context.l10n.appTitle}',
    ),
  );
}
