import 'package:bloc/bloc.dart';

import '../../data/language_preference_store.dart';
import '../../domain/language_preference.enum.dart';
import 'language_state.dart';

export 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(const LanguageState());

  Future<void> load() async {
    emit(LanguageState(preference: await LanguagePreferenceStore.get()));
  }

  Future<void> select(LanguagePreference preference) async {
    emit(LanguageState(preference: preference));
    await LanguagePreferenceStore.set(preference);
  }
}
