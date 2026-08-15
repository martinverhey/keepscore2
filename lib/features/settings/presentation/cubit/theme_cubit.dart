import 'package:bloc/bloc.dart';

import '../../data/theme_preference_store.dart';
import '../../domain/theme_preference.enum.dart';
import 'theme_state.dart';

export 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  Future<void> load() async {
    emit(ThemeState(preference: await ThemePreferenceStore.get()));
  }

  Future<void> select(ThemePreference preference) async {
    emit(ThemeState(preference: preference));
    await ThemePreferenceStore.set(preference);
  }
}
