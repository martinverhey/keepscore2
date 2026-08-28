import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/settings/domain/theme_preference.enum.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(binding.platformDispatcher.clearPlatformBrightnessTestValue);

  test(
    'falls back to the device brightness when nothing has been stored',
    () async {
      SharedPreferences.setMockInitialValues({});
      binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      final cubit = ThemeCubit();
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.preference, ThemePreference.dark);
    },
  );

  test('prefers a stored preference over the device brightness', () async {
    SharedPreferences.setMockInitialValues({'theme_preference': 'light'});
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    final cubit = ThemeCubit();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.preference, ThemePreference.light);
  });

  test(
    'toggling flips the preference and persists it for the next launch',
    () async {
      SharedPreferences.setMockInitialValues({'theme_preference': 'light'});
      final cubit = ThemeCubit();
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.toggle();

      final prefs = await SharedPreferences.getInstance();
      expect(cubit.state.preference, ThemePreference.dark);
      expect(prefs.getString('theme_preference'), 'dark');

      await cubit.toggle();

      expect(cubit.state.preference, ThemePreference.light);
      expect(prefs.getString('theme_preference'), 'light');
    },
  );
}
