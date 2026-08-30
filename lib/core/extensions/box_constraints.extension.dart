import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

extension BoxConstraintsContentInset on BoxConstraints {
  double get contentGutter {
    final gutter = (maxWidth - kContentMaxWidth) / 2;
    return gutter > 0 ? gutter : 0;
  }

  double get contentHorizontalInset {
    final gutter = contentGutter;
    return gutter > AppSpacing.md ? gutter : AppSpacing.md;
  }
}
