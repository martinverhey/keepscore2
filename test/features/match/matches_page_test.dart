import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/core/widgets/list_header.dart';
import 'package:keepscore2/core/widgets/speech_bubble.dart';
import 'package:keepscore2/core/widgets/state_views.dart';
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
import 'package:keepscore2/features/match/presentation/cubit/planned_match_cubit.dart';
import 'package:keepscore2/features/match/presentation/widgets/planned_match_card.dart';
import 'package:keepscore2/features/match/presentation/widgets/day_header.dart';
import 'package:keepscore2/features/match/presentation/pages/game_type_filter_sheet.dart';
import 'package:keepscore2/features/match/presentation/widgets/game_type_filter_button.dart';
import 'package:keepscore2/features/match/presentation/widgets/match_card.dart';
import 'package:keepscore2/features/match/presentation/pages/matches.page.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/tournament/domain/bracket.model.dart';
import 'package:keepscore2/features/tournament/domain/tournament.model.dart';
import 'package:keepscore2/features/tournament/domain/tournament_repository.dart';
import 'package:keepscore2/features/tournament/presentation/cubit/tournament_cubit.dart';
import 'package:keepscore2/features/tournament/presentation/widgets/tournament_button.dart';
import 'package:keepscore2/features/tournament/presentation/widgets/tournament_card.dart';
import 'package:keepscore2/features/tournament/presentation/widgets/bracket_view.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

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

Tournament _tournament({
  TournamentStatus status = TournamentStatus.active,
  String? winnerPlayerId,
}) => Tournament(
  id: 't1',
  competitionId: _competitionId,
  seasonId: 's1',
  size: 4,
  status: status,
  createdAt: DateTime(2026, 9, 11),
  winnerPlayerId: winnerPlayerId,
  createdBy: 'u-ada',
);

TournamentMatch _bracketMatch(
  int round,
  int slot, {
  String? a,
  String? b,
  String? winner,
}) => TournamentMatch(
  id: 'tm$round-$slot',
  tournamentId: 't1',
  round: round,
  slot: slot,
  playerA: a == null ? null : TournamentEntrant(playerId: a, displayName: a),
  playerB: b == null ? null : TournamentEntrant(playerId: b, displayName: b),
  winnerPlayerId: winner,
);

Bracket _bracket() => Bracket.fromMatches([
  _bracketMatch(1, 0, a: 'Ada', b: 'Bo'),
  _bracketMatch(1, 1, a: 'Cas', b: 'Dee'),
  _bracketMatch(2, 0),
]);

Bracket _finishedBracket() => Bracket.fromMatches([
  _bracketMatch(1, 0, a: 'Ada', b: 'Bo', winner: 'Ada'),
  _bracketMatch(1, 1, a: 'Cas', b: 'Dee', winner: 'Cas'),
  _bracketMatch(2, 0, a: 'Ada', b: 'Cas', winner: 'Ada'),
]);

Player _player(String id, String name) =>
    Player(id: id, competitionId: _competitionId, displayName: name, isActive: true);

Future<GameTypeFilterCubit> _pumpMatchesPage(
  WidgetTester tester, {
  Set<GameType> played = const {GameType.oneVOne, GameType.twoVTwo},
  List<MatchEntry>? feed,
  bool hostsBar = false,
  Tournament? tournament,
  Bracket bracket = const Bracket([]),
  List<Player> roster = const [],
  List<String> prePick = const [],
  PlannedMatchCubit? plannedMatches,
}) async {
  final auth = MockAuthRepository();
  final competitions = MockCompetitionRepository();
  final players = MockPlayerRepository();
  final matches = MockMatchRepository();
  final tournaments = MockTournamentRepository();

  when(
    () => auth.currentUser,
  ).thenReturn(const AuthUser(id: 'u-ada', displayName: 'Ada', isGuest: false));
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());
  when(
    () => players.currentPlayers(_competitionId),
  ).thenAnswer((_) async => roster);
  when(() => players.watch(any())).thenAnswer((_) => const Stream.empty());
  when(
    () => matches.watch(_competitionId),
  ).thenAnswer((_) => Stream.value(null));
  when(
    () => matches.seasonGameTypes(_competitionId),
  ).thenAnswer((_) async => played);
  when(
    () => matches.feed(
      competitionId: any(named: 'competitionId'),
      gameType: any(named: 'gameType'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async =>
        feed ??
        [
          for (var day = 5; day >= 1; day--)
            for (var index = 0; index < 3; index++) _match(day, index),
        ],
  );

  when(() => tournaments.latest(any())).thenAnswer((_) async => tournament);
  when(() => tournaments.bracket(any())).thenAnswer((_) async => bracket);
  when(
    () => tournaments.watchTournaments(any()),
  ).thenAnswer((_) => const Stream.empty());
  when(
    () => tournaments.watchBracket(any()),
  ).thenAnswer((_) => const Stream.empty());

  final authBloc = AuthBloc(auth);
  final gameTypeFilterCubit = GameTypeFilterCubit();
  final plannedMatchCubit = plannedMatches ?? PlannedMatchCubit();
  addTearDown(authBloc.close);
  addTearDown(gameTypeFilterCubit.close);
  if (plannedMatches == null) addTearDown(plannedMatchCubit.close);

  await plannedMatchCubit.select(_competitionId);
  if (prePick.isNotEmpty) await plannedMatchCubit.plan(prePick);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<GameTypeFilterCubit>.value(value: gameTypeFilterCubit),
        BlocProvider<PlannedMatchCubit>.value(value: plannedMatchCubit),
        BlocProvider(create: (_) => CompetitionCubit(competitions, authBloc)),
        BlocProvider(
          create: (_) => PlayersCubit(players, _competitionId)..load(),
        ),
        BlocProvider(
          create: (_) =>
              MatchListCubit(matches, gameTypeFilterCubit, _competitionId),
        ),
        BlocProvider(
          create: (_) => TournamentCubit(tournaments, _competitionId)..load(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: hostsBar
            ? _hostedPage()
            : const MatchesPage(competitionId: _competitionId),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return gameTypeFilterCubit;
}

Widget _hostedPage() {
  return MediaQuery(
    data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
    child: AdaptiveBottomBarHost(
      bar: const SizedBox(height: AppGlass.barHeight),
      action: AdaptiveBottomBarAction(
        glyph: AdaptiveGlyph.add,
        label: 'New match',
        onPressed: () {},
      ),
      child: const MatchesPage(competitionId: _competitionId),
    ),
  );
}

void _jumpTo(WidgetTester tester, double offset) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .jumpTo(offset);

Future<void> _scrollTo(WidgetTester tester, double offset) async {
  _jumpTo(tester, offset);
  await tester.pumpAndSettle();
}

Finder _sheetOption(String label) => find.descendant(
  of: find.byType(GameTypeFilterSheet),
  matching: find.text(label),
);

Finder _dayHeader(int day) => find.byWidgetPredicate(
  (widget) => widget is DayHeader && widget.day == DateTime(2026, 8, day),
);

Finder _dayHeaderLabel(int day) =>
    find.descendant(of: _dayHeader(day), matching: find.byType(Text));

Finder _barDay(int day) => find.descendant(
  of: find.byType(AdaptiveTopBar),
  matching: find.text(
    DateFormat.MMMMEEEEd('en').format(DateTime(2026, 8, day)),
  ),
);

double _scrollOntoCaptionLine(WidgetTester tester, int day) {
  final bar = find.byType(AdaptiveTopBar);
  final captionLine =
      tester.getRect(bar).top +
      MediaQuery.paddingOf(tester.element(bar)).top +
      AdaptiveTopBar.subtitleTop;
  return tester.getRect(_dayHeaderLabel(day)).top - captionLine;
}

Finder _matchCard(String id) => find.byWidgetPredicate(
  (widget) => widget is MatchCard && widget.match.id == id,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('pre-picked matches head the list as scoreless placeholders', (
    tester,
  ) async {
    await _pumpMatchesPage(
      tester,
      roster: [_player('p-ada', 'Ada'), _player('p-bo', 'Bo')],
      prePick: const ['p-ada', 'p-bo'],
    );

    expect(find.byType(PlannedMatchCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PlannedMatchCard),
        matching: find.text('Ada'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(PlannedMatchCard),
        matching: find.text('vs'),
      ),
      findsOneWidget,
    );

    final header = tester.getRect(find.text('Pre-picked'));
    final placeholder = tester.getRect(find.byType(PlannedMatchCard));
    final firstMatch = tester.getRect(find.byType(MatchCard).first);

    expect(header.bottom, lessThanOrEqualTo(placeholder.top));
    expect(placeholder.bottom, lessThanOrEqualTo(firstMatch.top));
  });

  testWidgets('a pre-picked match whose player left the roster is dropped', (
    tester,
  ) async {
    await _pumpMatchesPage(
      tester,
      roster: [_player('p-ada', 'Ada')],
      prePick: const ['p-ada', 'p-bo'],
    );

    expect(find.byType(PlannedMatchCard), findsNothing);
    expect(find.text('Pre-picked'), findsNothing);
  });

  testWidgets('removing a placeholder takes it off the list', (tester) async {
    await _pumpMatchesPage(
      tester,
      roster: [
        _player('p-ada', 'Ada'),
        _player('p-bo', 'Bo'),
        _player('p-cas', 'Cas'),
      ],
      prePick: const ['p-ada', 'p-bo', 'p-cas'],
    );

    expect(find.byType(PlannedMatchCard), findsNWidgets(3));

    await tester.tap(
      find.descendant(
        of: find.byType(PlannedMatchCard).first,
        matching: find.byType(AdaptiveIconButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlannedMatchCard), findsNWidgets(2));

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.byType(PlannedMatchCard), findsNothing);
  });

  testWidgets('placeholders replace the empty state when nothing is played', (
    tester,
  ) async {
    await _pumpMatchesPage(
      tester,
      feed: const [],
      roster: [_player('p-ada', 'Ada'), _player('p-bo', 'Bo')],
      prePick: const ['p-ada', 'p-bo'],
    );

    expect(find.byType(PlannedMatchCard), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
    expect(find.byType(SpeechBubble), findsNothing);
  });

  tearDown(() {
    AppPlatform.debugOverrideCupertino = null;
    AppPlatform.debugOverrideWideWeb = null;
    AppPlatform.debugOverrideLiquidGlass = null;
  });

  testWidgets('centres the empty message and hangs the new match bubble '
      'above the action', (tester) async {
    await _pumpMatchesPage(tester, feed: const []);

    final region = tester.getRect(
      find
          .ancestor(of: find.byType(EmptyState), matching: find.byType(Center))
          .first,
    );
    final viewport = tester.getRect(find.byType(CustomScrollView));

    expect(region.height, greaterThan(viewport.height / 2));
    expect(
      tester.getRect(find.text('Matches will show up here.')).center.dy,
      closeTo(region.center.dy, 1),
    );

    expect(
      region.bottom,
      lessThanOrEqualTo(viewport.bottom - AdaptiveFloatingAction.diameter),
    );

    final bubble = tester.getRect(find.byType(SpeechBubble));
    expect(bubble.width, region.width);
    expect(bubble.height, lessThan(region.height / 4));
    expect(bubble.top, greaterThan(region.center.dy));
    expect(bubble.bottom, region.bottom);
    expect(find.text('Press the + below to create a new match.'), findsOne);
  });

  testWidgets('the empty state clears the glass bar it is hosted above', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = true;
    AppPlatform.debugOverrideLiquidGlass = true;
    await _pumpMatchesPage(tester, feed: const [], hostsBar: true);

    final region = tester.getRect(
      find
          .ancestor(of: find.byType(EmptyState), matching: find.byType(Center))
          .first,
    );
    final action = tester.getRect(find.byType(AdaptiveFloatingAction));

    expect(region.bottom, lessThanOrEqualTo(action.top));
    expect(region.bottom, greaterThan(action.top - AppSpacing.lg));
    expect(
      tester.getRect(find.byType(SpeechBubble)).bottom,
      lessThanOrEqualTo(action.top),
    );
  });

  for (final useCupertino in [false, true]) {
    testWidgets('the day header stays put while its matches scroll under it '
        '(cupertino: $useCupertino)', (tester) async {
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
    });
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

  testWidgets('the day headers scroll away under the glass bar', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = true;
    AppPlatform.debugOverrideLiquidGlass = true;
    await _pumpMatchesPage(tester);

    final headerBefore = tester.getRect(_dayHeader(5));
    final cardBefore = tester.getRect(_matchCard('m5-2'));

    await _scrollTo(tester, 100);

    expect(
      headerBefore.top - tester.getRect(_dayHeader(5)).top,
      cardBefore.top - tester.getRect(_matchCard('m5-2')).top,
    );
  });

  testWidgets('the glass bar names no day while the first header is still '
      'readable', (tester) async {
    AppPlatform.debugOverrideCupertino = true;
    AppPlatform.debugOverrideLiquidGlass = true;
    await _pumpMatchesPage(tester);

    expect(_barDay(5), findsNothing);

    await _scrollTo(tester, _scrollOntoCaptionLine(tester, 5) - 1);

    expect(_barDay(5), findsNothing);
  });

  testWidgets('the glass bar names the day scrolled behind it', (tester) async {
    AppPlatform.debugOverrideCupertino = true;
    AppPlatform.debugOverrideLiquidGlass = true;
    await _pumpMatchesPage(tester);

    await _scrollTo(tester, _scrollOntoCaptionLine(tester, 5) + 1);

    expect(_barDay(5), findsOneWidget);

    await _scrollTo(tester, 400);

    expect(_barDay(4), findsOneWidget);
    expect(_barDay(5), findsNothing);
  });

  testWidgets('the bar picks the day up where the list header left it', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = true;
    AppPlatform.debugOverrideLiquidGlass = true;
    await _pumpMatchesPage(tester);

    await _scrollTo(tester, _scrollOntoCaptionLine(tester, 5));

    expect(
      tester.getRect(_barDay(5)).top,
      moreOrLessEquals(tester.getRect(_dayHeaderLabel(5)).top, epsilon: 0.5),
    );
  });

  testWidgets('one day name replaces the other without shifting sideways', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = true;
    AppPlatform.debugOverrideLiquidGlass = true;
    await _pumpMatchesPage(tester);

    await _scrollTo(tester, _scrollOntoCaptionLine(tester, 5) + 1);

    _jumpTo(tester, 400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getRect(_barDay(4)).left, tester.getRect(_barDay(5)).left);
  });

  testWidgets('the filter offers only the game types played this season', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    await _pumpMatchesPage(
      tester,
      played: const {GameType.oneVOne, GameType.twoVTwo},
    );

    await tester.tap(find.byType(GameTypeFilterButton));
    await tester.pumpAndSettle();

    expect(find.byType(GameTypeFilterSheet), findsOneWidget);
    expect(_sheetOption('All'), findsOneWidget);
    expect(_sheetOption('1v1'), findsOneWidget);
    expect(_sheetOption('2v2'), findsOneWidget);
    expect(_sheetOption('3v3'), findsNothing);
    expect(_sheetOption('4v4'), findsNothing);
    expect(_sheetOption('Mixed'), findsNothing);
  });

  testWidgets('a filter on a game type nobody has played yet stays offered', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    final filter = await _pumpMatchesPage(
      tester,
      played: const {GameType.oneVOne},
    );
    await filter.select(GameType.fourVFour);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GameTypeFilterButton));
    await tester.pumpAndSettle();

    expect(_sheetOption('4v4'), findsOneWidget);
    expect(_sheetOption('1v1'), findsOneWidget);
    expect(_sheetOption('2v2'), findsNothing);
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
      find.descendant(of: find.byType(ListHeader), matching: find.text('2v2')),
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
    testWidgets('the filter button carries no label of its own '
        '(cupertino: $useCupertino)', (tester) async {
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
    });
  }

  testWidgets('the empty state points its bubble at the sidebar on wide web', (
    tester,
  ) async {
    AppPlatform.debugOverrideCupertino = false;
    AppPlatform.debugOverrideWideWeb = true;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMatchesPage(tester, feed: const []);

    final region = tester.getRect(
      find
          .ancestor(of: find.byType(EmptyState), matching: find.byType(Center))
          .first,
    );
    final bubble = tester.getRect(find.byType(SpeechBubble));

    expect(
      tester.widget<SpeechBubble>(find.byType(SpeechBubble)).tail,
      SpeechBubbleTail.left,
    );
    expect(bubble.top, region.top);
    expect(bubble.bottom, lessThan(region.center.dy));
    expect(
      tester.getRect(find.text('Matches will show up here.')).center.dy,
      closeTo(region.center.dy, 1),
    );
    expect(region.bottom, tester.getRect(find.byType(CustomScrollView)).bottom);
  });

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

  testWidgets('no tournament means no card, but the action is still there', (
    tester,
  ) async {
    await _pumpMatchesPage(tester);

    expect(find.byType(TournamentCard), findsNothing);
    expect(find.byType(TournamentButton), findsOneWidget);
  });

  testWidgets('a running tournament heads the page, above the first day', (
    tester,
  ) async {
    await _pumpMatchesPage(
      tester,
      tournament: _tournament(),
      bracket: _bracket(),
    );

    expect(find.byType(TournamentCard), findsOneWidget);
    expect(
      tester.getRect(find.byType(TournamentCard)).bottom,
      lessThan(tester.getRect(_dayHeader(5)).top),
    );
  });

  testWidgets('the card names the round and who is up next', (tester) async {
    await _pumpMatchesPage(
      tester,
      tournament: _tournament(),
      bracket: _bracket(),
    );

    expect(find.text('Semi-finals'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Ada'), findsWidgets);
  });

  testWidgets('a finished tournament names its champion instead', (
    tester,
  ) async {
    await _pumpMatchesPage(
      tester,
      tournament: _tournament(
        status: TournamentStatus.completed,
        winnerPlayerId: 'p-ada',
      ),
      bracket: _finishedBracket(),
    );

    expect(find.text('Champion'), findsOneWidget);
    expect(find.text('In progress'), findsNothing);
  });

  testWidgets('tapping the card opens the bracket', (tester) async {
    await _pumpMatchesPage(
      tester,
      tournament: _tournament(),
      bracket: _bracket(),
    );

    await tester.tap(find.byType(TournamentCard));
    await tester.pumpAndSettle();

    expect(find.byType(BracketView), findsOneWidget);
  });
}
