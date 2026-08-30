import '../theme/app_tokens.dart';

extension DoubleRatingLabel on double {
  String get ratingLabel => round().toString();
}

extension DoubleContentGutter on double {
  double get contentGutter {
    final gutter = (this - kContentMaxWidth) / 2;
    return gutter > 0 ? gutter : 0;
  }
}
