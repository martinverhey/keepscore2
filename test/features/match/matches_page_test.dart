import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/core/widgets/list_header.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/match/domain/game_type.enum.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_list_cubit.dart';
import 'package:keepscore2/features/match/presentation/widgets/day_header.dart';
import 'package:keepscore2/features/match/presentation/widgets/game_type_filter_button.dart';
import 'package:keepscore2/features/match/presentation/widgets/match_card.dart';
import 'package:keepscore2/features/match/presentation/widgets/matches.page.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

const _competitionId = 'c1';

MatchEntry _match(int day, int index) => MatchEntry(
  id: 'm$day-$index',
  competitionId: _competitionId,
  seasonId: 's1',
  playedAt: DateTime(2026, 8, day, 20 - index),
  teamAScore: 11,
  teamBScore: 7,
  teamARating: 1000,
  teamBRating: 1000,
  teamA: const [
    MatchParticipant(
      playerId: 'p-ada',
      displayName: 'Ada',
      ratingBefore: 1000,
      ratingDelta: 12,
    ),
  ],
  teamB: const [
    MatchParticipant(
      playerId: 'p-bo',
      displayName: 'Bo',
      ratingBefore: 1000,
      ratingDelta: -12,
    ),
  ],
);

Future<GameTypeFilterCubit> _pumpMatchesPage(WidgetTester tester) async {
  final auth = MockAuthRepository();
  final competitions = MockCompetitionRepository();
  final players = MockPlayerRepository();
  final matches = MockMatchRepository();

  when(
    () => auth.currentUser,
  ).thenReturn(const AuthUser(id: 'u-ada', displayName: 'Ada', isGuest: false));
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
  when(() => players.currentPlayers(_competitionId)).thenAnswer((_) async => []);
  when(() => matches.watch(_competitionId)).thenAnswer((_) => Stream.value(null));
  when(
    () => matches.feed(
      competitionId: any(named: 'competitionId'),
      gameType: any(named: 'gameType'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => [
      for (var day = 5; day >= 1; day--)
        for (var index = 0; index < 3; index++) _match(day, index),
    ],
  );

  final authBloc = AuthBloc(auth);
  final gameTypeFilterCubit = GameTypeFilterCubit();
  addTearDown(authBloc.close);
  addTearDown(gameTypeFilterCubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
        BlocProvider(create: (_) => CompetitionCubit(competitions, authBloc)),
        BlocProvider(create: (_) => PlayersCubit(players, _competitionId)),
        BlocProvider(
          create: (_) =>
              MatchListCubit(matches, gameTypeFilterCubit, _competitionId),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MatchesPage(competitionId: _competitionId),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return gameTypeFilterCubit;
}

Future<void> _scrollTo(WidgetTester tester, double offset) async {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(offset);
  await tester.pumpAndSettle();
}

Finder _dayHeader(int day) => find.byWidgetPredicate(
  (widget) => widget is DayHeader && widget.day == DateTime(2026, 8, day),
);

Finder _matchCard(String id) => find.byWidgetPredicate(
  (widget) => widget is MatchCard && widget.match.id == id,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() {
    AppPlatform.debugOverrideCupertino = null;
    AppPlatform.debugOverrideWideWeb = null;
  });

  for (final useCupertino in [false, true]) {
    testWidgets(
      'the day header stays put while its matches scroll under it '
      '(cupertino: $useCupertino)',
      (tester) async {
        AppPlatform.debugOverrideCupertino = useCupertino;
        await _pumpMatchesPage(tester);

        final headerBefore = tester.getRect(_dayHeader(5));
        final cardBefore = tester.getRect(_matchCard('m5-2'));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
        await tester.pumpAndSettle();

        final headerAfter = tester.getRect(_dayHeader(5));
        final cardAfter = tester.getRect(_matchCard('m5-2'));

        expect(headerAfter.top, greaterThanOrEqualTo(0));
        expect(
          cardBefore.top - cardAfter.top,
          greaterThan(headerBefore.top - headerAfter.top),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('each day takes over the pinned slot as it reaches the top', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    await _pumpMatchesPage(tester);

    await _scrollTo(tester, 300);
    final pinnedTop = tester.getRect(_dayHeader(5)).top;

    await _scrollTo(tester, 600);

    expect(tester.getRect(_dayHeader(4)).top, pinnedTop);
  });

  testWidgets('a filtered list is headed by the game type it is filtered to', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    final filter = await _pumpMatchesPage(tester);

    expect(find.byType(ListHeader), findsNothing);

    await filter.select(GameType.twoVTwo);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ListHeader),
        matching: find.text('2v2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the filter button reads as active only while filtering', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    final filter = await _pumpMatchesPage(tester);

    Finder barAction() => find.descendant(
      of: find.byType(GameTypeFilterButton),
      matching: find.byType(AdaptiveBarAction),
    );

    expect(tester.widget<AdaptiveBarAction>(barAction()).active, isFalse);

    await filter.select(GameType.twoVTwo);
    await tester.pumpAndSettle();

    expect(tester.widget<AdaptiveBarAction>(barAction()).active, isTrue);
  });

  for (final useCupertino in [false, true]) {
    testWidgets(
      'the filter button carries no label of its own '
      '(cupertino: $useCupertino)',
      (tester) async {
        AppPlatform.debugOverrideCupertino = useCupertino;
        final filter = await _pumpMatchesPage(tester);
        await filter.select(GameType.twoVTwo);
        await tester.pumpAndSettle();

        expect(find.byType(GameTypeFilterButton), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(GameTypeFilterButton),
            matching: find.byType(Text),
          ),
          findsNothing,
        );
      },
    );
  }

  testWidgets('the list keeps to the centered content column on wide web', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    AppPlatform.debugOverrideWideWeb = true;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMatchesPage(tester);

    final header = tester.getRect(_dayHeader(5));

    expect(header.left, greaterThanOrEqualTo(400));
    expect(header.right, lessThanOrEqualTo(1040));
    expect(tester.getRect(_matchCard('m5-0')).width, lessThanOrEqualTo(640));
  });
}
