import 'package:flutter/widgets.dart';

extension BuildContextLocale on BuildContext {
  String get languageTag => Localizations.localeOf(this).toLanguageTag();
}
