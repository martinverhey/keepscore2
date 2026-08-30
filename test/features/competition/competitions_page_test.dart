import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive_floating_action.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/core/widgets/curved_arrow.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/join_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competitions.page.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_add_sheet.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_competition_sheet.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

Future<void> _pumpHarness(WidgetTester tester, {required bool isGuest}) async {
  SharedPreferences.setMockInitialValues({});
  AppPlatform.debugOverrideCupertino = false;

  final auth = MockAuthRepository();
  final competitions = MockCompetitionRepository();

  when(
    () => auth.currentUser,
  ).thenReturn(AuthUser(id: 'u-ada', displayName: 'Ada', isGuest: isGuest));
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
  when(() => competitions.myCompetitions()).thenAnswer((_) async => []);

  final authBloc = AuthBloc(auth);
  addTearDown(authBloc.close);

  getIt.registerFactory<JoinCompetitionCubit>(
    () => JoinCompetitionCubit(competitions),
  );
  addTearDown(() => getIt.reset(dispose: false));

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CompetitionsPage()),
      GoRoute(path: '/create', builder: (_, _) => const _RouteStub('create')),
    ],
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => CompetitionCubit(competitions, authBloc)),
        BlocProvider(
          create: (_) => CompetitionListCubit(competitions, authBloc),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    AppPlatform.debugOverrideCupertino = null;
    AppPlatform.debugOverrideWideWeb = null;
  });

  testWidgets('a guest goes straight to join, with no create choice', (
    tester,
  ) async {
    await _pumpHarness(tester, isGuest: true);

    await tester.tap(find.byType(AdaptiveFloatingAction));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionAddSheet), findsNothing);
    expect(find.byType(JoinCompetitionSheet), findsOneWidget);
    expect(find.text('create'), findsNothing);
  });

  testWidgets('the empty state points a curved arrow at the add button', (
    tester,
  ) async {
    await _pumpHarness(tester, isGuest: false);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    expect(find.text(l10n.competitionsAddHint), findsOneWidget);
    expect(find.byType(CurvedArrow), findsOneWidget);
  });

  testWidgets('a guest is pointed at joining instead of adding', (
    tester,
  ) async {
    await _pumpHarness(tester, isGuest: true);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    expect(find.text(l10n.competitionsJoinHint), findsOneWidget);
    expect(find.byType(CurvedArrow), findsOneWidget);
  });

  testWidgets('the hint survives the wide web layout', (tester) async {
    AppPlatform.debugOverrideWideWeb = true;

    await _pumpHarness(tester, isGuest: false);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    expect(find.text(l10n.competitionsAddHint), findsOneWidget);
    expect(find.byType(CurvedArrow), findsOneWidget);
  });

  testWidgets('a registered user picks between create and join', (
    tester,
  ) async {
    await _pumpHarness(tester, isGuest: false);

    await tester.tap(find.byType(AdaptiveFloatingAction));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionAddSheet)),
    );
    expect(find.text(l10n.competitionsCreate), findsOneWidget);
    expect(find.text(l10n.competitionsJoin), findsOneWidget);
  });
}

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}
