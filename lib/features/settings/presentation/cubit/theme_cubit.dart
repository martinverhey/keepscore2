import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/extensions/theme_preference.extension.dart';
import '../../data/theme_preference_store.dart';
import '../../domain/theme_preference.enum.dart';
import 'theme_state.dart';

export 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(preference: _devicePreference()));

  Future<void> load() async {
    emit(
      ThemeState(
        preference: await ThemePreferenceStore.get() ?? _devicePreference(),
      ),
    );
  }

  Future<void> toggle() async {
    final preference = state.preference.toggled;
    emit(ThemeState(preference: preference));
    await ThemePreferenceStore.set(preference);
  }
}

ThemePreference _devicePreference() =>
    switch (WidgetsBinding.instance.platformDispatcher.platformBrightness) {
      Brightness.light => ThemePreference.light,
      Brightness.dark => ThemePreference.dark,
    };
