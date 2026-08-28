import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/settings/domain/language_preference.enum.dart';
import 'package:keepscore2/features/settings/presentation/cubit/language_cubit.dart';
import 'package:keepscore2/features/settings/presentation/pages/language.page.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('picking Dutch selects and persists it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = LanguageCubit();
    final auth = MockAuthRepository();
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
    final authBloc = AuthBloc(auth);
    addTearDown(cubit.close);
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: authBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LanguagePage(),
        ),
      ),
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(LanguagePage)));

    expect(find.text(l10n.languageOptionSystem), findsOneWidget);
    expect(find.text(l10n.languageOptionEnglish), findsOneWidget);
    expect(find.text(l10n.languageOptionDutch), findsOneWidget);

    await tester.tap(find.text(l10n.languageOptionDutch));
    await tester.pumpAndSettle();

    expect(cubit.state.preference, LanguagePreference.dutch);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language_preference'), 'dutch');
    expect(tester.takeException(), isNull);
  });
}
