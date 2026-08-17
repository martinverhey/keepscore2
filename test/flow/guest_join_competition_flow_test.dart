import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keepscore2/app/router/go_router_refresh_stream.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive_tab_bar.dart';
import 'package:keepscore2/core/widgets/adaptive/app_platform.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:keepscore2/features/auth/presentation/pages/sign_in.page.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/domain/join_preview.model.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/cubit/join_competition_cubit.dart';
import 'package:keepscore2/features/competition/presentation/pages/competition_content.page.dart';
import 'package:keepscore2/features/competition/presentation/pages/join_competition.page.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard.model.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
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

const _joinCode = 'HDHS39';
const _competitionId = 'c1';

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets(
    'guest logs in, joins a competition and finds the leaderboard and matches',
    (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      SharedPreferences.setMockInitialValues({});

      final auth = MockAuthRepository();
      final competitions = MockCompetitionRepository();
      final players = MockPlayerRepository();
      final matches = MockMatchRepository();
      final leaderboard = MockLeaderboardRepository();

      final authEvents = StreamController<AuthUser?>.broadcast();
      addTearDown(authEvents.close);

      final gameTypeFilterCubit = GameTypeFilterCubit();
      addTearDown(gameTypeFilterCubit.close);

      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.watchUser()).thenAnswer((_) => authEvents.stream);
      when(
        () => auth.availableProviders,
      ).thenReturn(const AuthProviders(apple: false, google: false));
      when(() => auth.signInAsGuest()).thenAnswer((_) async {
        authEvents.add(
          const AuthUser(id: 'guest-1', displayName: 'Guest', isGuest: true),
        );
      });

      when(() => competitions.preview(_joinCode)).thenAnswer(
        (_) async => const JoinPreview(
          competitionId: _competitionId,
          name: 'Office Table Tennis',
          ownerName: 'Ada',
          playerCount: 2,
          alreadyMember: false,
          claimable: [ClaimablePlayer(id: 'p-chris', displayName: 'Chris')],
        ),
      );
      when(
        () => competitions.join(
          joinCode: _joinCode,
          claimPlayerId: 'p-chris',
          displayName: null,
        ),
      ).thenAnswer(
        (_) async => const Player(
          id: 'p-chris',
          competitionId: _competitionId,
          displayName: 'Chris',
          isActive: true,
          userId: 'guest-1',
        ),
      );
      when(() => competitions.overview(_competitionId)).thenAnswer(
        (_) async => CompetitionOverview(
          competition: Competition(
            id: _competitionId,
            joinCode: _joinCode,
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
          playerCount: 2,
          matchCount: 1,
          myPlayerId: 'p-chris',
        ),
      );

      when(() => players.currentPlayers(_competitionId)).thenAnswer(
        (_) async => const [
          Player(
            id: 'p-chris',
            competitionId: _competitionId,
            displayName: 'Chris',
            isActive: true,
            userId: 'guest-1',
          ),
          Player(
            id: 'p-ada',
            competitionId: _competitionId,
            displayName: 'Ada',
            isActive: true,
            userId: 'p-ada',
          ),
        ],
      );

      when(
        () => matches.feed(competitionId: _competitionId, limit: 20),
      ).thenAnswer(
        (_) async => [
          MatchEntry(
            id: 'm1',
            competitionId: _competitionId,
            seasonId: 's1',
            playedAt: DateTime.utc(2026, 8, 9),
            teamAScore: 3,
            teamBScore: 1,
            teamARating: 1050,
            teamBRating: 950,
            teamA: const [
              MatchParticipant(
                playerId: 'p-ada',
                displayName: 'Ada',
                ratingBefore: 1000,
                ratingDelta: 50,
              ),
            ],
            teamB: const [
              MatchParticipant(
                playerId: 'p-chris',
                displayName: 'Chris',
                ratingBefore: 1000,
                ratingDelta: -50,
              ),
            ],
          ),
        ],
      );
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
        () => leaderboard.leaderboards(
          competitionId: _competitionId,
          seasonId: 's1',
        ),
      ).thenAnswer(
        (_) async => const [
          Leaderboard(
            seasonId: 's1',
            competitionId: _competitionId,
            playerId: 'p-ada',
            displayName: 'Ada',
            isClaimed: true,
            isOwner: false,
            rating: 1050,
            played: 3,
            wins: 2,
            losses: 1,
            draws: 0,
            rank: 1,
          ),
          Leaderboard(
            seasonId: 's1',
            competitionId: _competitionId,
            playerId: 'p-chris',
            displayName: 'Chris',
            isClaimed: true,
            isOwner: false,
            rating: 950,
            played: 3,
            wins: 1,
            losses: 2,
            draws: 0,
            rank: 2,
          ),
        ],
      );
      when(
        () => leaderboard.watchLeaderboards(
          competitionId: _competitionId,
          seasonId: 's1',
        ),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => leaderboard.medals(
          _competitionId,
          gameType: any(named: 'gameType'),
        ),
      ).thenAnswer((_) async => const []);

      final authBloc = AuthBloc(auth);
      addTearDown(authBloc.close);

      final router = _buildRouter(
        authBloc,
        authRepository: auth,
        competitionRepository: competitions,
        playerRepository: players,
        matchRepository: matches,
        leaderboardRepository: leaderboard,
        gameTypeFilterCubit: gameTypeFilterCubit,
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

      final l10n = AppLocalizations.of(tester.element(find.byType(SignInPage)));

      await _continueAsGuest(tester, l10n);
      await _joinCompetitionAndClaimPlayer(tester, l10n, competitions);
      _expectLeaderboardTabIsPopulated();
      await _expectMatchesTabIsPopulated(tester, l10n);

      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _continueAsGuest(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.text(l10n.authContinueAsGuest));
  await tester.pumpAndSettle();

  expect(find.byType(_HomeStub), findsOneWidget);
}

Future<void> _joinCompetitionAndClaimPlayer(
  WidgetTester tester,
  AppLocalizations l10n,
  MockCompetitionRepository competitions,
) async {
  await tester.tap(find.text('Join a competition'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), _joinCode);
  await tester.pump();
  await tester.tap(find.text(l10n.joinLookUp));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Chris'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.joinConfirm));
  await tester.pumpAndSettle();

  verify(
    () => competitions.join(
      joinCode: _joinCode,
      claimPlayerId: 'p-chris',
      displayName: null,
    ),
  ).called(1);
}

void _expectLeaderboardTabIsPopulated() {
  expect(find.byType(CompetitionContent), findsOneWidget);
  expect(find.text('Ada'), findsWidgets);
  expect(find.text('Chris'), findsWidgets);
}

Future<void> _expectMatchesTabIsPopulated(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AdaptiveBottomTabBar),
      matching: find.text(l10n.matchesTitle),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('3 – 1'), findsOneWidget);
}

GoRouter _buildRouter(
  AuthBloc authBloc, {
  required AuthRepository authRepository,
  required CompetitionRepository competitionRepository,
  required PlayerRepository playerRepository,
  required MatchRepository matchRepository,
  required LeaderboardRepository leaderboardRepository,
  required GameTypeFilterCubit gameTypeFilterCubit,
}) {
  return GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!authBloc.state.isAuthenticated) {
        return location == '/sign-in' ? null : '/sign-in';
      }
      if (location == '/sign-in') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => BlocProvider(
          create: (_) => SignInCubit(authRepository),
          child: const SignInPage(),
        ),
      ),
      GoRoute(path: '/home', builder: (context, state) => const _HomeStub()),
      GoRoute(
        path: '/join',
        builder: (context, state) => BlocProvider(
          create: (_) => JoinCompetitionCubit(competitionRepository),
          child: const JoinCompetitionPage(),
        ),
      ),
      GoRoute(
        path: '/competition/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    CompetitionCubit(competitionRepository, id)..load(),
              ),
              BlocProvider(create: (_) => PlayersCubit(playerRepository, id)),
              BlocProvider(
                create: (_) =>
                    MatchListCubit(matchRepository, gameTypeFilterCubit, id),
              ),
              BlocProvider(
                create: (_) => LeaderboardCubit(
                  leaderboardRepository,
                  gameTypeFilterCubit,
                  id,
                ),
              ),
            ],
            child: CompetitionContent(competitionId: id),
          );
        },
      ),
    ],
  );
}

class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.push('/join'),
          child: const Text('Join a competition'),
        ),
      ),
    );
  }
}
