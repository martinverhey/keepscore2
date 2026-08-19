import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competition_content.page.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_section.enum.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

const _competitionId = 'c1';

Future<GoRouter> _pumpHarness(
  WidgetTester tester, {
  List<RouteBase> extraRoutes = const [],
}) async {
  SharedPreferences.setMockInitialValues({});

  final auth = MockAuthRepository();
  final competitions = MockCompetitionRepository();
  final players = MockPlayerRepository();
  final matches = MockMatchRepository();
  final leaderboard = MockLeaderboardRepository();

  when(
    () => auth.currentUser,
  ).thenReturn(const AuthUser(id: 'p-ada', displayName: 'Ada', isGuest: false));
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

  when(() => competitions.overview(_competitionId)).thenAnswer(
    (_) async => CompetitionOverview(
      competition: Competition(
        id: _competitionId,
        joinCode: 'HDHS39',
        name: 'Office Table Tennis',
        ownerId: 'p-ada',
        seasonLength: SeasonLength.monthly,
        timezone: 'Europe/Amsterdam',
        startingRating: 1000,
        kFactor: 32,
        movEnabled: true,
        movCap: 2.5,
        allowDraws: true,
        createdAt: DateTime.utc(2026, 8, 1),
      ),
      playerCount: 1,
      matchCount: 0,
      myPlayerId: 'p-ada',
    ),
  );
  when(
    () => players.currentPlayers(_competitionId),
  ).thenAnswer((_) async => []);
  when(
    () => matches.feed(competitionId: _competitionId, limit: 20),
  ).thenAnswer((_) async => []);
  when(
    () => matches.watch(_competitionId),
  ).thenAnswer((_) => const Stream.empty());

  final seasonStart = DateTime.utc(2026, 8, 1);
  final seasonEnd = DateTime.utc(2026, 9, 1);
  when(() => leaderboard.currentSeason(_competitionId)).thenAnswer(
    (_) async =>
        SeasonWindow(id: 's1', startsAt: seasonStart, endsAt: seasonEnd),
  );
  when(
    () =>
        leaderboard.leaderboards(competitionId: _competitionId, seasonId: 's1'),
  ).thenAnswer((_) async => []);
  when(
    () => leaderboard.watchLeaderboards(
      competitionId: _competitionId,
      seasonId: 's1',
    ),
  ).thenAnswer((_) => const Stream.empty());
  when(() => leaderboard.medals(_competitionId)).thenAnswer((_) async => []);

  final authBloc = AuthBloc(auth);
  final gameTypeFilterCubit = GameTypeFilterCubit();
  addTearDown(authBloc.close);
  addTearDown(gameTypeFilterCubit.close);

  final router = GoRouter(
    initialLocation: '/competition/$_competitionId',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _CompetitionsStub()),
      GoRoute(
        path: '/competition/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => CompetitionCubit(competitions, id)..load(),
              ),
              BlocProvider(create: (_) => PlayersCubit(players, id)),
              BlocProvider(
                create: (_) => MatchListCubit(matches, gameTypeFilterCubit, id),
              ),
              BlocProvider(create: (_) => LeaderboardCubit(leaderboard, id)),
            ],
            child: CompetitionContent(competitionId: id),
          );
        },
        routes: extraRoutes,
      ),
    ],
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}

void main() {
  tearDown(() {
    AppPlatform.debugOverrideCupertino = null;
    AppPlatform.debugOverrideWideWeb = null;
  });

  testWidgets(
    'tapping the competition name goes to the competitions list, not settings',
    (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      await _pumpHarness(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(CompetitionContent)),
      );
      expect(find.text(l10n.competitionSettings), findsNothing);

      await tester.tap(find.text('Office Table Tennis'));
      await tester.pumpAndSettle();

      expect(find.byType(_CompetitionsStub), findsOneWidget);
      expect(find.text(l10n.competitionSettings), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('picking Matches from the sidebar of a page pushed on top (e.g. '
      'History) lands on Matches, not Leaderboard', (tester) async {
    AppPlatform.debugOverrideWideWeb = true;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHarness(
      tester,
      extraRoutes: [
        GoRoute(
          path: 'settings/history',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(CompetitionSection.matches),
              child: const Text('pretend-history-select-matches'),
            ),
          ),
        ),
      ],
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CompetitionContent)),
    );

    expect(find.text(l10n.leaderboardTitle), findsWidgets);

    await tester.tap(find.text(l10n.historyTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text('pretend-history-select-matches'));
    await tester.pumpAndSettle();

    expect(find.byType(CompetitionContent), findsOneWidget);
    expect(find.text(l10n.matchesTitle), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _CompetitionsStub extends StatelessWidget {
  const _CompetitionsStub();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Competitions')));
}
