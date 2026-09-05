import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/domain/join_preview.model.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_list_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/join_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competition_shell.dart';
import 'package:keepscore2/features/competition/presentation/pages/competitions.page.dart';
import 'package:keepscore2/features/competition/presentation/pages/join_competition_sheet.dart';
import 'package:keepscore2/features/competition/presentation/widgets/competition_scope.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/leaderboard/presentation/widgets/leaderboard.page.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:keepscore2/features/match/presentation/widgets/matches.page.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

const _joinCode = 'HDHS39';

CompetitionOverview _overview(String id, String name) => CompetitionOverview(
  competition: Competition(
    id: id,
    joinCode: id == 'c1' ? 'CODEC1' : _joinCode,
    name: name,
    ownerId: 'user-1',
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
  myPlayerId: 'player-$id',
);

Leaderboard _row(String id, String displayName) => Leaderboard(
  seasonId: 'season-$id',
  competitionId: id,
  playerId: 'player-$id',
  displayName: displayName,
  isClaimed: true,
  isOwner: true,
  rating: 1200,
  played: 3,
  wins: 2,
  losses: 1,
  draws: 0,
  rank: 1,
);

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('joining while already inside a competition opens the new one', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    SharedPreferences.setMockInitialValues({});

    final auth = MockAuthRepository();
    final competitions = MockCompetitionRepository();
    final players = MockPlayerRepository();
    final matches = MockMatchRepository();
    final leaderboard = MockLeaderboardRepository();

    when(() => auth.currentUser).thenReturn(
      const AuthUser(id: 'user-1', displayName: 'Ada', isGuest: false),
    );
    when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

    when(() => competitions.myCompetitions()).thenAnswer(
      (_) async => [
        _overview('c1', 'Office Table Tennis'),
        _overview('c2', 'Padel Ladder'),
      ],
    );
    when(
      () => competitions.overview('c1'),
    ).thenAnswer((_) async => _overview('c1', 'Office Table Tennis'));
    when(
      () => competitions.overview('c2'),
    ).thenAnswer((_) async => _overview('c2', 'Padel Ladder'));

    when(() => competitions.preview(_joinCode)).thenAnswer(
      (_) async => const JoinPreview(
        competitionId: 'c2',
        name: 'Padel Ladder',
        ownerName: 'Ada',
        playerCount: 1,
        alreadyMember: false,
        claimable: [ClaimablePlayer(id: 'player-c2', displayName: 'Chris')],
      ),
    );
    when(
      () => competitions.join(
        joinCode: _joinCode,
        claimPlayerId: 'player-c2',
        displayName: null,
      ),
    ).thenAnswer(
      (_) async => const Player(
        id: 'player-c2',
        competitionId: 'c2',
        displayName: 'Chris',
        isActive: true,
        userId: 'user-1',
      ),
    );

    for (final id in ['c1', 'c2']) {
      when(() => players.watch(id)).thenAnswer((_) => const Stream.empty());
      when(() => players.currentPlayers(id)).thenAnswer(
        (_) async => [
          Player(
            id: 'player-$id',
            competitionId: id,
            displayName: 'Ada',
            isActive: true,
            userId: 'user-1',
          ),
        ],
      );
      when(
        () => matches.feed(competitionId: id, limit: 20),
      ).thenAnswer((_) async => []);
      when(
        () => matches.seasonGameTypes(id),
      ).thenAnswer((_) async => const <GameType>{});
      when(() => matches.watch(id)).thenAnswer((_) => const Stream.empty());
      when(() => leaderboard.currentSeason(id)).thenAnswer(
        (_) async => SeasonWindow(
          id: 'season-$id',
          startsAt: DateTime.utc(2026, 8, 1),
          endsAt: DateTime.utc(2026, 9, 1),
        ),
      );
      when(
        () => leaderboard.leaderboards(
          competitionId: id,
          seasonId: 'season-$id',
        ),
      ).thenAnswer((_) async => [_row(id, id == 'c1' ? 'Ada One' : 'Ada Two')]);
      when(
        () => leaderboard.watchLeaderboards(
          competitionId: id,
          seasonId: 'season-$id',
        ),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => leaderboard.watchPlayers(competitionId: id),
      ).thenAnswer((_) => const Stream.empty());
      when(() => leaderboard.medals(id)).thenAnswer((_) async => []);
    }

    final authBloc = AuthBloc(auth);
    final gameTypeFilterCubit = GameTypeFilterCubit();
    addTearDown(authBloc.close);
    addTearDown(gameTypeFilterCubit.close);

    getIt.registerFactory<JoinCompetitionCubit>(
      () => JoinCompetitionCubit(competitions),
    );
    addTearDown(() => getIt.reset(dispose: false));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => CompetitionCubit(competitions, authBloc)),
          BlocProvider(
            create: (_) => CompetitionListCubit(competitions, authBloc),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _buildRouter(
            playerRepository: players,
            matchRepository: matches,
            leaderboardRepository: leaderboard,
            gameTypeFilterCubit: gameTypeFilterCubit,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada One'), findsWidgets);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LeaderboardPage)),
    );

    await tester.tap(find.text('Office Table Tennis'));
    await tester.pumpAndSettle();
    expect(find.byType(CompetitionsPage), findsOneWidget);

    await tester.tap(find.text(l10n.competitionsJoinShort));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.joinScanEnterCode));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), _joinCode);
    await tester.pump();
    await tester.tap(find.text(l10n.joinLookUp));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chris'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(JoinCompetitionSheet),
        matching: find.text(l10n.joinConfirm),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LeaderboardPage), findsOneWidget);
    expect(find.text('Padel Ladder'), findsWidgets);
    expect(find.text('Ada Two'), findsWidgets);
    expect(
      tester
          .element(find.byType(LeaderboardPage))
          .read<LeaderboardCubit>()
          .competitionId,
      'c2',
    );
    expect(tester.takeException(), isNull);
  });
}

GoRouter _buildRouter({
  required PlayerRepository playerRepository,
  required MatchRepository matchRepository,
  required LeaderboardRepository leaderboardRepository,
  required GameTypeFilterCubit gameTypeFilterCubit,
}) {
  return GoRouter(
    initialLocation: '/competition/c1/leaderboard',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            adaptivePage(context, child: const CompetitionsPage()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) {
          final id = state.pathParameters['id']!;
          return adaptivePageNoWebTransition<void>(
            child: CompetitionScope(
              competitionId: id,
              child: KeyedSubtree(
                key: ValueKey(id),
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => PlayersCubit(playerRepository, id),
                    ),
                  ],
                  child: child,
                ),
              ),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/competition/:id',
            redirect: (context, state) =>
                state.matchedLocation == state.uri.path
                ? '${state.matchedLocation}/leaderboard'
                : null,
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, navigationShell) => CompetitionShell(
                  competitionId: state.pathParameters['id']!,
                  navigationShell: navigationShell,
                ),
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'leaderboard',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return BlocProvider(
                            key: ValueKey(id),
                            create: (_) =>
                                LeaderboardCubit(leaderboardRepository, id),
                            child: LeaderboardPage(competitionId: id),
                          );
                        },
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'matches',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return BlocProvider(
                            key: ValueKey(id),
                            create: (_) => MatchListCubit(
                              matchRepository,
                              gameTypeFilterCubit,
                              id,
                            ),
                            child: MatchesPage(competitionId: id),
                          );
                        },
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'competitions',
                        builder: (_, _) => const CompetitionsPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
