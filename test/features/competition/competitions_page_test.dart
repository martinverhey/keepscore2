import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive_floating_action.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/core/widgets/curved_arrow.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/join_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competitions.page.dart';
import 'package:keepscore2/features/competition/presentation/widgets/active_competition_card.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_card.dart';
import 'package:keepscore2/features/competition/presentation/widgets/join_competition_sheet.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

CompetitionOverview _overview(String id, String name, String joinCode) =>
    CompetitionOverview(
      competition: Competition(
        id: id,
        joinCode: joinCode,
        name: name,
        ownerId: 'u-ada',
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

Future<void> _pumpHarness(
  WidgetTester tester, {
  required bool isGuest,
  List<CompetitionOverview> competitions = const [],
  String? activeId,
  Size? surfaceSize,
}) async {
  SharedPreferences.setMockInitialValues({});
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  AppPlatform.debugOverrideCupertino = false;

  final auth = MockAuthRepository();
  final competitionRepository = MockCompetitionRepository();

  when(
    () => auth.currentUser,
  ).thenReturn(AuthUser(id: 'u-ada', displayName: 'Ada', isGuest: isGuest));
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
  when(
    () => competitionRepository.myCompetitions(),
  ).thenAnswer((_) async => competitions);
  for (final overview in competitions) {
    when(
      () => competitionRepository.overview(overview.id),
    ).thenAnswer((_) async => overview);
  }

  final authBloc = AuthBloc(auth);
  addTearDown(authBloc.close);

  final competitionCubit = CompetitionCubit(competitionRepository, authBloc);
  if (activeId != null) await competitionCubit.select(activeId);

  getIt.registerFactory<JoinCompetitionCubit>(
    () => JoinCompetitionCubit(competitionRepository),
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
        BlocProvider.value(value: competitionCubit),
        BlocProvider(
          create: (_) => CompetitionListCubit(competitionRepository, authBloc),
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

  testWidgets('a guest is offered joining and not creating', (tester) async {
    await _pumpHarness(tester, isGuest: true);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    expect(find.byTooltip(l10n.competitionsAdd), findsNothing);

    await tester.tap(find.text(l10n.competitionsJoinShort));
    await tester.pumpAndSettle();

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

  testWidgets('the active competition is spotlighted with its code and QR', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      isGuest: false,
      competitions: [
        _overview('c1', 'Office Table Tennis', 'HDHS39'),
        _overview('c2', 'Padel Friday', 'QQWW11'),
      ],
      activeId: 'c1',
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    final card = find.byType(ActiveCompetitionCard);

    expect(card, findsOneWidget);
    expect(find.text(l10n.competitionsActive), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Office Table Tennis')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('HDHS39')),
      findsOneWidget,
    );
    expect(find.descendant(of: card, matching: find.byType(QrImageView)),
        findsOneWidget);
  });

  testWidgets('the spotlighted competition is not repeated in the list', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      isGuest: false,
      competitions: [
        _overview('c1', 'Office Table Tennis', 'HDHS39'),
        _overview('c2', 'Padel Friday', 'QQWW11'),
      ],
      activeId: 'c1',
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );

    expect(find.byType(CompetitionCard), findsOneWidget);
    expect(find.text('Padel Friday'), findsOneWidget);
    expect(find.text(l10n.competitionsOther), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CompetitionCard),
        matching: find.text('Office Table Tennis'),
      ),
      findsNothing,
    );
  });

  testWidgets('with no competition active every competition is a plain card', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      isGuest: false,
      competitions: [
        _overview('c1', 'Office Table Tennis', 'HDHS39'),
        _overview('c2', 'Padel Friday', 'QQWW11'),
      ],
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );

    expect(find.byType(ActiveCompetitionCard), findsNothing);
    expect(find.byType(CompetitionCard), findsNWidgets(2));
    expect(find.text(l10n.competitionsOther), findsNothing);
  });

  testWidgets('the spotlighted name runs the full width of the card', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      isGuest: false,
      competitions: [_overview('c1', 'Office Table Tennis', 'HDHS39')],
      activeId: 'c1',
    );

    final nameRow = tester.getRect(
      find
          .ancestor(
            of: find.text('Office Table Tennis'),
            matching: find.byType(Row),
          )
          .first,
    );
    final card = tester.getRect(find.byType(ActiveCompetitionCard));
    final code = tester.getRect(find.text('HDHS39'));

    expect(nameRow.right, greaterThan(code.left));
    expect(nameRow.right, greaterThan(card.right - AppSpacing.lg));
  });

  testWidgets('the spotlight fits a narrow phone without overflowing', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      isGuest: false,
      competitions: [_overview('c1', 'Office Table Tennis', 'HDHS39')],
      activeId: 'c1',
      surfaceSize: const Size(320, 640),
    );

    expect(find.byType(ActiveCompetitionCard), findsOneWidget);
  });

  testWidgets('a registered user gets a create action beside the join one', (
    tester,
  ) async {
    await _pumpHarness(tester, isGuest: false);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    expect(find.text(l10n.competitionsJoinShort), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.competitionsAdd));
    await tester.pumpAndSettle();

    expect(find.text('create'), findsOneWidget);
  });

  testWidgets('the page carries no floating action', (tester) async {
    await _pumpHarness(tester, isGuest: false);

    expect(find.byType(AdaptiveFloatingAction), findsNothing);
  });

  testWidgets('an empty list offers signing out at the bottom', (tester) async {
    await _pumpHarness(tester, isGuest: false);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    final signOut = find.text(l10n.authSignOut);

    expect(signOut, findsOneWidget);
    expect(
      tester.getRect(signOut).top,
      greaterThan(tester.getRect(find.text(l10n.competitionsEmpty)).bottom),
    );
  });

  testWidgets('signing out goes away once there is a competition', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      isGuest: false,
      competitions: [_overview('c1', 'Office Table Tennis', 'HDHS39')],
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionsPage)),
    );
    expect(find.text(l10n.authSignOut), findsNothing);
  });
}

class _RouteStub extends StatelessWidget {
  const _RouteStub(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}
