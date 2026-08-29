import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../extensions/build_context.extension.dart';

void setPageTitle(BuildContext context, String label) {
  if (!kIsWeb) return;
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(label: '$label · ${context.l10n.appTitle}'),
  );
}
