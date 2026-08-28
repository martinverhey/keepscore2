import 'package:flutter/widgets.dart';

import '../../features/settings/domain/language_preference.enum.dart';

extension LanguagePreferenceLocale on LanguagePreference {
  Locale? get locale => switch (this) {
    LanguagePreference.system => null,
    LanguagePreference.english => const Locale('en'),
    LanguagePreference.dutch => const Locale('nl'),
  };
}
