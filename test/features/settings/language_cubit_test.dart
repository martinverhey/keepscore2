import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/settings/domain/language_preference.enum.dart';
import 'package:keepscore2/features/settings/presentation/cubit/language_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  blocTest<LanguageCubit, LanguageState>(
    'defaults to system when nothing has been stored',
    setUp: () => SharedPreferences.setMockInitialValues({}),
    build: LanguageCubit.new,
    act: (cubit) => cubit.load(),
    expect: () => [const LanguageState(preference: LanguagePreference.system)],
  );

  blocTest<LanguageCubit, LanguageState>(
    'loads a previously stored preference',
    setUp: () => SharedPreferences.setMockInitialValues({
      'language_preference': 'dutch',
    }),
    build: LanguageCubit.new,
    act: (cubit) => cubit.load(),
    expect: () => [const LanguageState(preference: LanguagePreference.dutch)],
  );

  blocTest<LanguageCubit, LanguageState>(
    'selecting a preference emits it and persists it for the next launch',
    setUp: () => SharedPreferences.setMockInitialValues({}),
    build: LanguageCubit.new,
    act: (cubit) => cubit.select(LanguagePreference.english),
    expect: () => [const LanguageState(preference: LanguagePreference.english)],
    verify: (_) async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language_preference'), 'english');
    },
  );
}
