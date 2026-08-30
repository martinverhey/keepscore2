import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'double.extension.dart';

extension BoxConstraintsContentInset on BoxConstraints {
  double get contentGutter => maxWidth.contentGutter;

  double get contentHorizontalInset {
    final gutter = contentGutter;
    return gutter > AppSpacing.md ? gutter : AppSpacing.md;
  }
}
