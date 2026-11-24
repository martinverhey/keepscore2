import '../theme/app_tokens.dart';

extension DoubleRatingLabel on double {
  String get ratingLabel => round().toString();
}

extension DoubleInputLabel on double {
  String get inputLabel =>
      this == roundToDouble() ? round().toString() : '$this';
}

extension DoubleContentGutter on double {
  double get contentGutter {
    final gutter = (this - kContentMaxWidth) / 2;
    return gutter > 0 ? gutter : 0;
  }
}
