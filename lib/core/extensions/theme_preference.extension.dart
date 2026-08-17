import 'package:flutter/material.dart';

import '../../features/settings/domain/theme_preference.enum.dart';

extension ThemePreferenceMode on ThemePreference {
  ThemeMode get mode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}

extension ThemePreferenceBrightnessOverride on ThemePreference {
  Brightness? get brightnessOverride => switch (this) {
    ThemePreference.system => null,
    ThemePreference.light => Brightness.light,
    ThemePreference.dark => Brightness.dark,
  };
}
