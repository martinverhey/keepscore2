import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/settings/domain/theme_preference.enum.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/features/settings/presentation/pages/theme.page.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('picking Dark selects and persists it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ThemeCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ThemePage(),
        ),
      ),
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ThemePage)));

    expect(find.text(l10n.themeOptionSystem), findsOneWidget);
    expect(find.text(l10n.themeOptionLight), findsOneWidget);
    expect(find.text(l10n.themeOptionDark), findsOneWidget);

    await tester.tap(find.text(l10n.themeOptionDark));
    await tester.pumpAndSettle();

    expect(cubit.state.preference, ThemePreference.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_preference'), 'dark');
    expect(tester.takeException(), isNull);
  });
}
