import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/config/app_version.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/features/settings/presentation/pages/profile.page.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

MockAuthRepository _auth() {
  final auth = MockAuthRepository();
  when(() => auth.currentUser).thenReturn(
    const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
  );
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
  when(() => auth.signOut()).thenAnswer((_) async {});
  return auth;
}

Future<AppLocalizations> _pump(WidgetTester tester, AuthRepository auth) async {
  final authBloc = AuthBloc(auth);
  addTearDown(authBloc.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfilePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return AppLocalizations.of(tester.element(find.byType(ProfilePage)));
}

void main() {
  testWidgets('the app version is shown below the language row', (
    tester,
  ) async {
    AppVersion.debugOverrideLabel = '9.9.9 (42)';
    addTearDown(() => AppVersion.debugOverrideLabel = null);

    final l10n = await _pump(tester, _auth());
    final version = find.text(l10n.settingsVersionLabel('9.9.9 (42)'));
    final language = find.text(l10n.settingsLanguageTitle);

    expect(version, findsOneWidget);
    expect(
      tester.getTopLeft(version).dy,
      greaterThan(tester.getTopLeft(language).dy),
    );
    expect(
      tester.getCenter(version).dx,
      moreOrLessEquals(tester.getCenter(find.byType(ProfilePage)).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'signing out from the profile calls through to the auth repository',
    (tester) async {
      final auth = _auth();
      final l10n = await _pump(tester, auth);

      expect(find.text(l10n.profilePageTitle), findsWidgets);
      expect(find.text(l10n.competitionSettingsSectionSystem), findsOneWidget);
      expect(find.text(l10n.settingsDarkModeTitle), findsOneWidget);
      expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);

      final signOutButton = find.text(l10n.authSignOut);
      await tester.ensureVisible(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      verify(() => auth.signOut()).called(1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('carries no competition rows', (tester) async {
    final l10n = await _pump(tester, _auth());

    expect(find.text(l10n.competitionSettingsSectionCompetition), findsNothing);
    expect(find.text(l10n.historyTitle), findsNothing);
    expect(find.text(l10n.playersManageTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
