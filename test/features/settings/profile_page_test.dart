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
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/profile/presentation/widgets/initials_circle.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/features/settings/presentation/pages/profile.page.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

const _me = Player(
  id: 'p1',
  competitionId: 'c1',
  displayName: 'Ada Lovelace',
  isActive: true,
  userId: 'user-1',
);

const _other = Player(
  id: 'p2',
  competitionId: 'c1',
  displayName: 'Bram',
  isActive: true,
  userId: 'user-2',
);

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
  playerCount: 2,
  matchCount: 0,
  myPlayerId: 'p1',
);

class _Harness {
  _Harness() {
    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(
      () => competitions.overview('c1'),
    ).thenAnswer((_) async => _overview());
    when(
      () => players.currentPlayers('c1'),
    ).thenAnswer((_) async => [_me, _other]);
    when(() => players.watch('c1')).thenAnswer((_) => const Stream.empty());
  }

  final auth = MockAuthRepository();
  final competitions = MockCompetitionRepository();
  final players = MockPlayerRepository();

  Future<AppLocalizations> pump(WidgetTester tester) async {
    final authBloc = AuthBloc(auth);
    final competitionCubit = CompetitionCubit(competitions, authBloc)
      ..select('c1');
    final playersCubit = PlayersCubit(players, 'c1')..load();
    addTearDown(playersCubit.close);
    addTearDown(competitionCubit.close);
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: competitionCubit),
          BlocProvider.value(value: playersCubit),
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
}

void main() {
  testWidgets('shows your avatar and name centred above the change button', (
    tester,
  ) async {
    final l10n = await _Harness().pump(tester);

    final avatar = find.byType(InitialsCircle);
    final name = find.text(_me.displayName);
    final change = find.text(l10n.profileChangeName);
    final pageCentre = tester.getCenter(find.byType(ProfilePage)).dx;

    expect(tester.widget<InitialsCircle>(avatar).displayName, _me.displayName);
    expect(find.text('AL'), findsOneWidget);
    expect(find.text(_other.displayName), findsNothing);
    expect(tester.getCenter(avatar).dx, moreOrLessEquals(pageCentre));
    expect(tester.getCenter(name).dx, moreOrLessEquals(pageCentre));
    expect(tester.getCenter(change).dx, moreOrLessEquals(pageCentre));
    expect(
      tester.getTopLeft(name).dy,
      greaterThan(tester.getTopLeft(avatar).dy),
    );
    expect(
      tester.getTopLeft(change).dy,
      greaterThan(tester.getTopLeft(name).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('change name opens the name sheet prefilled and renames you', (
    tester,
  ) async {
    final harness = _Harness();
    const renamed = Player(
      id: 'p1',
      competitionId: 'c1',
      displayName: 'Countess Ada',
      isActive: true,
      userId: 'user-1',
    );
    when(
      () => harness.players.rename(playerId: 'p1', displayName: 'Countess Ada'),
    ).thenAnswer((_) async => renamed);

    final l10n = await harness.pump(tester);

    await tester.tap(find.text(l10n.profileChangeName));
    await tester.pumpAndSettle();

    expect(find.text(l10n.joinNewPlayerNameTitle), findsOneWidget);
    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).controller!.text, _me.displayName);

    await tester.enterText(field, 'Countess Ada');
    await tester.tap(find.text(l10n.commonSave));
    await tester.pumpAndSettle();

    verify(
      () => harness.players.rename(playerId: 'p1', displayName: 'Countess Ada'),
    ).called(1);
    expect(find.text('Countess Ada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app version is shown below the language row', (
    tester,
  ) async {
    AppVersion.debugOverrideLabel = '9.9.9 (42)';
    addTearDown(() => AppVersion.debugOverrideLabel = null);

    final l10n = await _Harness().pump(tester);
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
      final harness = _Harness();
      final l10n = await harness.pump(tester);

      expect(find.text(l10n.competitionSettingsSectionSystem), findsOneWidget);
      expect(find.text(l10n.settingsDarkModeTitle), findsOneWidget);
      expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);

      final signOutButton = find.text(l10n.authSignOut);
      await tester.ensureVisible(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      verify(() => harness.auth.signOut()).called(1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('carries no competition rows', (tester) async {
    final l10n = await _Harness().pump(tester);

    expect(find.text(l10n.competitionSettingsSectionCompetition), findsNothing);
    expect(find.text(l10n.historyTitle), findsNothing);
    expect(find.text(l10n.playersManageTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
