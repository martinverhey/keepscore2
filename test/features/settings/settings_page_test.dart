import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/config/app_version.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/features/settings/presentation/pages/settings.page.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

CompetitionOverview _overview() => CompetitionOverview(
  competition: Competition(
    id: 'c1',
    joinCode: 'HDHS39',
    name: 'Office Table Tennis',
    ownerId: 'user-1',
    seasonLength: SeasonLength.monthly,
    timezone: 'Europe/Amsterdam',
    startingRating: 1000,
    kFactor: 32,
    movEnabled: true,
    movCap: 2.5,
    allowDraws: true,
    createdAt: DateTime.utc(2026, 8, 9),
  ),
  playerCount: 5,
  matchCount: 11,
);

void main() {
  testWidgets('the app version is shown below the language row', (
    tester,
  ) async {
    final competitions = MockCompetitionRepository();
    final auth = MockAuthRepository();

    when(
      () => competitions.overview('c1'),
    ).thenAnswer((_) async => _overview());
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

    AppVersion.debugOverrideLabel = '9.9.9 (42)';
    addTearDown(() => AppVersion.debugOverrideLabel = null);

    final authBloc = AuthBloc(auth);
    final competitionDetailCubit = CompetitionCubit(competitions, authBloc)
      ..select('c1');
    addTearDown(competitionDetailCubit.close);
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: competitionDetailCubit),
          BlocProvider.value(value: authBloc),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(competitionId: 'c1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsPage)));
    final version = find.text(l10n.settingsVersionLabel('9.9.9 (42)'));
    final language = find.text(l10n.settingsLanguageTitle);

    expect(version, findsOneWidget);
    expect(
      tester.getTopLeft(version).dy,
      greaterThan(tester.getTopLeft(language).dy),
    );
    expect(
      tester.getCenter(version).dx,
      moreOrLessEquals(tester.getCenter(find.byType(SettingsPage)).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'signing out from the settings menu calls through to the auth repository',
    (tester) async {
      final competitions = MockCompetitionRepository();
      final auth = MockAuthRepository();

      when(
        () => competitions.overview('c1'),
      ).thenAnswer((_) async => _overview());
      when(() => auth.currentUser).thenReturn(
        const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
      );
      when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
      when(() => auth.signOut()).thenAnswer((_) async {});

      final authBloc = AuthBloc(auth);
      final competitionDetailCubit = CompetitionCubit(competitions, authBloc)
        ..select('c1');
      addTearDown(competitionDetailCubit.close);
      addTearDown(authBloc.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: competitionDetailCubit),
            BlocProvider.value(value: authBloc),
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsPage(competitionId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsPage)),
      );

      expect(find.text(l10n.competitionSettingsSectionSystem), findsOneWidget);
      expect(find.text(l10n.settingsDarkModeTitle), findsOneWidget);
      expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);

      final signOutButton = find.text(l10n.authSignOut);
      expect(signOutButton, findsOneWidget);

      await tester.ensureVisible(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      verify(() => auth.signOut()).called(1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a member who is not the owner does not see competition settings',
    (tester) async {
      final competitions = MockCompetitionRepository();
      final auth = MockAuthRepository();

      when(
        () => competitions.overview('c1'),
      ).thenAnswer((_) async => _overview());
      when(() => auth.currentUser).thenReturn(
        const AuthUser(id: 'user-2', displayName: 'Bram', isGuest: false),
      );
      when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

      final authBloc = AuthBloc(auth);
      final competitionDetailCubit = CompetitionCubit(competitions, authBloc)
        ..select('c1');
      addTearDown(competitionDetailCubit.close);
      addTearDown(authBloc.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: competitionDetailCubit),
            BlocProvider.value(value: authBloc),
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsPage(competitionId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsPage)),
      );

      expect(find.text(l10n.configurationTitle), findsNothing);
      expect(find.text(l10n.playersManageTitle), findsNothing);
      expect(find.text(l10n.historyTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
