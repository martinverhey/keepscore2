import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

extension BoxConstraintsContentInset on BoxConstraints {
  double get contentHorizontalInset {
    final extra = (maxWidth - kContentMaxWidth) / 2;
    return extra > AppSpacing.md ? extra : AppSpacing.md;
  }
}
