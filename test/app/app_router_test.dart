import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/app.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/app/router/app_router.dart';
import 'package:keepscore2/core/data/recent_competition_store.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

CompetitionOverview _overview(String id) => CompetitionOverview(
  competition: Competition(
    id: id,
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
  late MockCompetitionRepository competitions;
  late MockAuthRepository auth;
  late AuthCubit authCubit;
  late CompetitionListCubit competitionListCubit;
  late CompetitionCubit competitionCubit;

  setUp(() {
    AppPlatform.debugOverrideCupertino = false;
    SharedPreferences.setMockInitialValues({'recent_competition_id': 'c1'});

    competitions = MockCompetitionRepository();
    auth = MockAuthRepository();

    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

    authCubit = AuthCubit(auth);
    competitionListCubit = CompetitionListCubit(competitions, authCubit);
    competitionCubit = CompetitionCubit(competitions, authCubit);

    getIt.registerSingleton<CompetitionListCubit>(competitionListCubit);
  });

  tearDown(() async {
    AppPlatform.debugOverrideCupertino = null;
    await getIt.reset(dispose: false);
    await competitionListCubit.close();
    await competitionCubit.close();
    await authCubit.close();
  });

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = createRouter(authCubit);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<CompetitionCubit>.value(value: competitionCubit),
          BlocProvider<CompetitionListCubit>.value(value: competitionListCubit),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: KeepScoreApp.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('a recent competition the user left is forgotten', (
    tester,
  ) async {
    when(() => competitions.myCompetitions()).thenAnswer((_) async => []);

    final router = await pumpApp(tester);

    expect(locationOf(router), Routes.home);
    expect(await RecentCompetitionStore.get(), isNull);
  });

  testWidgets('a failed list load keeps the recent competition', (
    tester,
  ) async {
    when(() => competitions.myCompetitions()).thenThrow(const NetworkFailure());

    final router = await pumpApp(tester);

    expect(locationOf(router), Routes.home);
    expect(await RecentCompetitionStore.get(), 'c1');
  });

  test('a stale recent id falls through to the newest competition, '
      'for one list request', () async {
    when(
      () => competitions.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c2'), _overview('c3')]);

    final target = await resolveHomeTarget(competitionListCubit);

    expect(target, Routes.competition('c2'));
    expect(await RecentCompetitionStore.get(), isNull);
    verify(() => competitions.myCompetitions()).called(1);
    verifyNever(() => competitions.overview(any()));
  });

  test('a recent competition the user is still in wins', () async {
    when(
      () => competitions.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c2'), _overview('c1')]);

    final target = await resolveHomeTarget(competitionListCubit);

    expect(target, Routes.competition('c1'));
    expect(await RecentCompetitionStore.get(), 'c1');
  });

  test('without a recent id the newest competition is entered', () async {
    SharedPreferences.setMockInitialValues({});
    when(
      () => competitions.myCompetitions(),
    ).thenAnswer((_) async => [_overview('c3'), _overview('c2')]);

    final target = await resolveHomeTarget(competitionListCubit);

    expect(target, Routes.competition('c3'));
  });

  test('an empty list stays home', () async {
    when(() => competitions.myCompetitions()).thenAnswer((_) async => []);

    expect(await resolveHomeTarget(competitionListCubit), isNull);
  });

  test('a failed load stays home and keeps the recent id', () async {
    when(() => competitions.myCompetitions()).thenThrow(const NetworkFailure());

    expect(await resolveHomeTarget(competitionListCubit), isNull);
    expect(await RecentCompetitionStore.get(), 'c1');
  });
}
