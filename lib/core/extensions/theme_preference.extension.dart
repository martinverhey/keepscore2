import 'package:flutter/material.dart';

import '../../features/settings/domain/theme_preference.enum.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/adaptive/adaptive_glyph.enum.dart';

extension ThemePreferenceMode on ThemePreference {
  ThemeMode get mode => switch (this) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}

extension ThemePreferenceBrightness on ThemePreference {
  Brightness get brightness => switch (this) {
    ThemePreference.light => Brightness.light,
    ThemePreference.dark => Brightness.dark,
  };
}

extension ThemePreferenceToggled on ThemePreference {
  ThemePreference get toggled => switch (this) {
    ThemePreference.light => ThemePreference.dark,
    ThemePreference.dark => ThemePreference.light,
  };
}

extension ThemePreferenceGlyph on ThemePreference {
  AdaptiveGlyph get glyph => switch (this) {
    ThemePreference.light => AdaptiveGlyph.light,
    ThemePreference.dark => AdaptiveGlyph.dark,
  };
}

extension ThemePreferenceLabel on ThemePreference {
  String label(AppLocalizations l10n) => switch (this) {
    ThemePreference.light => l10n.themeOptionLight,
    ThemePreference.dark => l10n.themeOptionDark,
  };
}
