import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/settings/domain/theme_preference.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  blocTest<ThemeCubit, ThemeState>(
    'defaults to system when nothing has been stored',
    setUp: () => SharedPreferences.setMockInitialValues({}),
    build: ThemeCubit.new,
    act: (cubit) => cubit.load(),
    expect: () => [const ThemeState(preference: ThemePreference.system)],
  );

  blocTest<ThemeCubit, ThemeState>(
    'loads a previously stored preference',
    setUp: () => SharedPreferences.setMockInitialValues({
      'theme_preference': 'dark',
    }),
    build: ThemeCubit.new,
    act: (cubit) => cubit.load(),
    expect: () => [const ThemeState(preference: ThemePreference.dark)],
  );

  blocTest<ThemeCubit, ThemeState>(
    'selecting a preference emits it and persists it for the next launch',
    setUp: () => SharedPreferences.setMockInitialValues({}),
    build: ThemeCubit.new,
    act: (cubit) => cubit.select(ThemePreference.light),
    expect: () => [const ThemeState(preference: ThemePreference.light)],
    verify: (_) async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_preference'), 'light');
    },
  );
}
