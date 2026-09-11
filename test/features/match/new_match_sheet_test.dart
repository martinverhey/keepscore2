import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.model.dart';
import 'package:keepscore2/features/auth/presentation/cubit/auth_bloc.dart';
import 'package:keepscore2/features/competition/domain/competition.model.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/presentation/cubit/competition_cubit.dart';
import 'package:keepscore2/features/leaderboard/domain/leaderboard_repository.dart';
import 'package:keepscore2/features/leaderboard/domain/season_window.model.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/core/widgets/selectable_row.dart';
import 'package:keepscore2/core/widgets/swipe_navigator.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/domain/match_repository.dart';
import 'package:keepscore2/features/match/domain/planned_match.model.dart';
import 'package:keepscore2/features/match/presentation/cubit/match_form_cubit.dart';
import 'package:keepscore2/features/match/presentation/cubit/planned_match_cubit.dart';
import 'package:keepscore2/features/match/presentation/widgets/new_match_keys.enum.dart';
import 'package:keepscore2/features/match/presentation/pages/new_match_sheet.dart';
import 'package:keepscore2/app/dependency_injection/injector.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/player/presentation/cubit/players_cubit.dart';
import 'package:keepscore2/features/player/presentation/pages/manage_players_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

Competition _competition() => Competition(
  id: 'c1',
  joinCode: 'HDHS39',
  name: 'Office Table Tennis',
  ownerId: 'u1',
  seasonLength: SeasonLength.monthly,
  timezone: 'Europe/Amsterdam',
  startingRating: 1000,
  kFactor: 32,
  movEnabled: false,
  movCap: 2.5,
  allowDraws: true,
  createdAt: DateTime(2026),
);

Player _player(String id, String name) =>
    Player(id: id, competitionId: 'c1', displayName: name, isActive: true);

typedef _Blocs = ({
  AuthBloc auth,
  CompetitionCubit competition,
  MatchFormCubit form,
  PlannedMatchCubit planned,
  PlayerRepository players,
});

_Blocs _blocs({
  List<String> teamA = const [],
  List<String> teamB = const [],
  String? myPlayerId,
}) {
  SharedPreferences.setMockInitialValues(const {});
  final auth = MockAuthRepository();
  final matches = MockMatchRepository();
  final competitions = MockCompetitionRepository();
  final players = MockPlayerRepository();
  final leaderboard = MockLeaderboardRepository();

  when(
    () => auth.currentUser,
  ).thenReturn(const AuthUser(id: 'u1', displayName: 'Ada', isGuest: false));
  when(() => auth.watchUser()).thenAnswer((_) => const Stream.empty());

  when(() => competitions.overview('c1')).thenAnswer(
    (_) async => CompetitionOverview(
      competition: _competition(),
      playerCount: 3,
      matchCount: 0,
      myPlayerId: myPlayerId,
    ),
  );
  when(
    () => matches.create(
      competitionId: any(named: 'competitionId'),
      teamA: any(named: 'teamA'),
      teamB: any(named: 'teamB'),
      scoreA: any(named: 'scoreA'),
      scoreB: any(named: 'scoreB'),
    ),
  ).thenAnswer((_) async => 'm1');
  when(() => players.watch(any())).thenAnswer((_) => const Stream.empty());
  when(() => players.currentPlayers('c1')).thenAnswer(
    (_) async => [
      _player('p1', 'Zoe'),
      _player('p2', 'Ada'),
      _player('p3', 'Mia'),
    ],
  );
  when(() => leaderboard.currentSeason('c1')).thenAnswer(
    (_) async => SeasonWindow(
      id: 's1',
      startsAt: DateTime(2026, 8),
      endsAt: DateTime(2026, 9),
    ),
  );
  when(
    () => leaderboard.leaderboards(competitionId: 'c1', seasonId: 's1'),
  ).thenAnswer((_) async => []);

  final form = MatchFormCubit(matches, competitions, players, leaderboard, 'c1')
    ..load(teamA: teamA, teamB: teamB);
  final authBloc = AuthBloc(auth);
  final competitionCubit = CompetitionCubit(competitions, authBloc)
    ..select('c1');
  final plannedMatchCubit = PlannedMatchCubit()..select('c1');
  addTearDown(form.close);
  addTearDown(authBloc.close);
  addTearDown(competitionCubit.close);
  addTearDown(plannedMatchCubit.close);

  return (
    auth: authBloc,
    competition: competitionCubit,
    form: form,
    planned: plannedMatchCubit,
    players: players,
  );
}

Widget _app({required _Blocs blocs, required Widget home}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: blocs.form),
      BlocProvider.value(value: blocs.auth),
      BlocProvider.value(value: blocs.competition),
      BlocProvider.value(value: blocs.planned),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Widget _sheetOpener() {
  return Builder(
    builder: (context) => Material(
      child: Center(
        child: TextButton(
          onPressed: () => showAdaptiveSheet<void>(
            context,
            confirmsDismissal: true,
            builder: (_) => const NewMatchSheet(),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Widget _prePickedOpener(PlannedMatch planned) {
  return Builder(
    builder: (context) => Material(
      child: Center(
        child: TextButton(
          onPressed: () => showAdaptiveSheet<void>(
            context,
            confirmsDismissal: true,
            builder: (_) => NewMatchSheet(planned: planned),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

MatchFormReady _ready(MatchFormCubit cubit) => cubit.state as MatchFormReady;

Future<void> _pickTeamsMode(WidgetTester tester) async {
  await tester.tap(find.text('Teams'));
  await tester.pumpAndSettle();
}

Future<void> _pickPrePickMode(WidgetTester tester) async {
  await tester.tap(find.text('Pre-pick'));
  await tester.pumpAndSettle();
}

Finder _prePickRow(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(SelectableRow));

bool _scoreAHasFocus(WidgetTester tester) => tester
    .widget<EditableText>(find.byType(EditableText).first)
    .focusNode
    .hasFocus;

void main() {
  testWidgets(
    'picking players from a team sheet renders them alphabetically inside that team',
    (tester) async {
      final blocs = _blocs();

      await tester.pumpWidget(
        _app(
          blocs: blocs,
          home: const Material(child: NewMatchSheet()),
        ),
      );
      await tester.pumpAndSettle();
      await _pickTeamsMode(tester);

      expect(find.byKey(const ValueKey(NewMatchKey.teamAreaA)), findsOneWidget);
      expect(find.byKey(const ValueKey(NewMatchKey.teamAreaB)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaA)));
      await tester.pumpAndSettle();

      final sheetNames = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();
      final sheetOrder = ['Ada', 'Mia', 'Zoe'].map(sheetNames.indexOf).toList();
      expect(sheetOrder, equals(List.of(sheetOrder)..sort()));

      await tester.tap(find.text('Ada'));
      await tester.tap(find.text('Zoe'));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final teamAText = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const ValueKey(NewMatchKey.teamAreaA)),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(teamAText, containsAllInOrder(['Ada', 'Zoe']));
      expect(teamAText, contains('1000'));

      await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaB)));
      await tester.pumpAndSettle();

      final otherSheetNames = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(otherSheetNames, contains('Mia'));
      expect(otherSheetNames, isNot(contains('Ada')));
      expect(otherSheetNames, isNot(contains('Zoe')));
    },
  );

  testWidgets(
    'managing players opens a sheet over the picker and refreshes its list',
    (tester) async {
      final blocs = _blocs();
      getIt.registerFactoryParam<PlayersCubit, String, void>(
        (competitionId, _) => PlayersCubit(blocs.players, competitionId),
      );
      addTearDown(getIt.reset);

      await tester.pumpWidget(
        _app(
          blocs: blocs,
          home: const Material(child: NewMatchSheet()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaA)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();

      expect(find.byType(ManagePlayersSheet), findsOneWidget);
      expect(
        find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
        findsOneWidget,
      );

      when(() => blocs.players.currentPlayers('c1')).thenAnswer(
        (_) async => [
          _player('p1', 'Zoe'),
          _player('p2', 'Ada'),
          _player('p3', 'Mia'),
          _player('p4', 'Ben'),
        ],
      );

      await tester.tap(
        find.descendant(
          of: find.byType(ManagePlayersSheet),
          matching: find.text('Done'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ManagePlayersSheet), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
          matching: find.text('Ben'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a team match walks from Team A to Team B and lands in the score field',
    (tester) async {
      final blocs = _blocs();

      await tester.pumpWidget(
        _app(
          blocs: blocs,
          home: const Material(child: NewMatchSheet()),
        ),
      );
      await tester.pumpAndSettle();
      await _pickTeamsMode(tester);

      await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaA)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ada'));
      await tester.tap(find.text('Zoe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
          matching: find.text('Team 2'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ada'), findsNothing);
      expect(find.text('Previous'), findsOneWidget);

      await tester.tap(find.text('Mia'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
        findsNothing,
      );
      expect(_ready(blocs.form).teamA.map((player) => player.id), ['p1', 'p2']);
      expect(_ready(blocs.form).teamB.map((player) => player.id), ['p3']);
      expect(_scoreAHasFocus(tester), isTrue);
    },
  );

  testWidgets('going back from Team B keeps what Team A already holds', (
    tester,
  ) async {
    final blocs = _blocs();

    await tester.pumpWidget(
      _app(
        blocs: blocs,
        home: const Material(child: NewMatchSheet()),
      ),
    );
    await tester.pumpAndSettle();
    await _pickTeamsMode(tester);

    await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaA)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
        matching: find.text('Team 1'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<SelectableRow>(
        find.ancestor(
          of: find.text('Ada'),
          matching: find.byType(SelectableRow),
        ),
      ),
      isA<SelectableRow>().having((row) => row.selected, 'selected', isTrue),
    );
  });

  testWidgets('1v1 picks one player a side and never asks for Next', (
    tester,
  ) async {
    final blocs = _blocs();

    await tester.pumpWidget(
      _app(
        blocs: blocs,
        home: const Material(child: NewMatchSheet()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('1v1'));
    await tester.pumpAndSettle();

    expect(find.text('Player 1'), findsWidgets);
    expect(find.text('Player 2'), findsWidgets);
    expect(find.text('Tap to pick a player'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey(NewMatchKey.teamAreaA)));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
        matching: find.text('Player 1'),
      ),
      findsOneWidget,
    );
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
        matching: find.text('Player 2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.text('Zoe'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey(NewMatchKey.teamPickerSheet)),
      findsNothing,
    );
    expect(_ready(blocs.form).teamA.map((player) => player.id), ['p2']);
    expect(_ready(blocs.form).teamB.map((player) => player.id), ['p1']);
    expect(_scoreAHasFocus(tester), isTrue);
  });

  testWidgets('swiping the form moves between the three modes', (tester) async {
    final blocs = _blocs();

    await tester.pumpWidget(
      _app(
        blocs: blocs,
        home: const Material(child: NewMatchSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(_ready(blocs.form).mode, MatchEntryMode.oneVsOne);

    await tester.fling(find.byType(SwipeNavigator), const Offset(-200, 0), 800);
    await tester.pumpAndSettle();

    expect(_ready(blocs.form).mode, MatchEntryMode.teams);
    expect(find.text('Team 1'), findsWidgets);

    await tester.fling(find.byType(SwipeNavigator), const Offset(-200, 0), 800);
    await tester.pumpAndSettle();

    expect(_ready(blocs.form).mode, MatchEntryMode.prePick);
    expect(find.text('Create matches'), findsOneWidget);

    await tester.fling(find.byType(SwipeNavigator), const Offset(-200, 0), 800);
    await tester.pumpAndSettle();

    expect(_ready(blocs.form).mode, MatchEntryMode.prePick);

    await tester.fling(find.byType(SwipeNavigator), const Offset(200, 0), 800);
    await tester.fling(find.byType(SwipeNavigator), const Offset(200, 0), 800);
    await tester.pumpAndSettle();

    expect(_ready(blocs.form).mode, MatchEntryMode.oneVsOne);
    expect(find.text('Player 1'), findsWidgets);

    await tester.fling(find.byType(SwipeNavigator), const Offset(200, 0), 800);
    await tester.pumpAndSettle();

    expect(_ready(blocs.form).mode, MatchEntryMode.oneVsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the pre-pick roster reads like the player picker', (
    tester,
  ) async {
    final blocs = _blocs(myPlayerId: 'p2');

    await tester.pumpWidget(
      _app(blocs: blocs, home: const Material(child: NewMatchSheet())),
    );
    await tester.pumpAndSettle();
    await _pickPrePickMode(tester);

    final tops = [
      for (final name in ['Ada', 'Mia', 'Zoe'])
        tester.getRect(_prePickRow(name)).top,
    ];

    expect(tops, equals(List.of(tops)..sort()));
    expect(
      tester.widget<SelectableRow>(_prePickRow('Ada')).labelColor,
      isNotNull,
    );
    expect(tester.widget<SelectableRow>(_prePickRow('Zoe')).labelColor, isNull);
  });

  testWidgets('pre-picking players plans a match for every pairing', (
    tester,
  ) async {
    final blocs = _blocs();

    await tester.pumpWidget(
      _app(blocs: blocs, home: _sheetOpener()),
    );
    await tester.pumpAndSettle();
    await _openSheet(tester);
    await _pickPrePickMode(tester);

    expect(find.text('Pick at least two players.'), findsOneWidget);

    await tester.tap(find.text('Ada'));
    await tester.tap(find.text('Mia'));
    await tester.pumpAndSettle();

    expect(find.text('1 match will show up on the list.'), findsOneWidget);

    await tester.tap(find.text('Zoe'));
    await tester.pumpAndSettle();

    expect(find.text('3 matches will show up on the list.'), findsOneWidget);

    await tester.tap(find.text('Create matches'));
    await tester.pumpAndSettle();

    expect(find.byType(NewMatchSheet), findsNothing);
    expect(blocs.planned.state.matches, hasLength(3));
    expect(
      blocs.planned.state.matches.map((match) => match.pairKey),
      containsAll(<String>['p1|p2', 'p2|p3', 'p1|p3']),
    );
  });

  testWidgets('a pre-picked match opens the sheet with both players in it', (
    tester,
  ) async {
    final blocs = _blocs(teamA: const ['p2'], teamB: const ['p3']);

    await tester.pumpWidget(
      _app(
        blocs: blocs,
        home: const Material(
          child: NewMatchSheet(
            planned: PlannedMatch(playerAId: 'p2', playerBId: 'p3'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_ready(blocs.form).teamA.single.displayName, 'Ada');
    expect(_ready(blocs.form).teamB.single.displayName, 'Mia');
    expect(find.byKey(const ValueKey(NewMatchKey.modeToggle)), findsNothing);
    expect(find.byType(SwipeNavigator), findsNothing);
  });

  testWidgets('saving a pre-picked match takes it off the planned list', (
    tester,
  ) async {
    final blocs = _blocs(teamA: const ['p2'], teamB: const ['p3']);
    await blocs.planned.plan(['p2', 'p3']);

    await tester.pumpWidget(
      _app(
        blocs: blocs,
        home: _prePickedOpener(
          const PlannedMatch(playerAId: 'p2', playerBId: 'p3'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.enterText(find.byType(EditableText).first, '11');
    await tester.enterText(find.byType(EditableText).last, '7');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save match'));
    await tester.pumpAndSettle();

    expect(find.byType(NewMatchSheet), findsNothing);
    expect(blocs.planned.state.matches, isEmpty);
  });

  testWidgets('removing a pre-picked match from its sheet drops it', (
    tester,
  ) async {
    final blocs = _blocs(teamA: const ['p2'], teamB: const ['p3']);
    await blocs.planned.plan(['p2', 'p3']);

    await tester.pumpWidget(
      _app(
        blocs: blocs,
        home: _prePickedOpener(
          const PlannedMatch(playerAId: 'p2', playerBId: 'p3'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openSheet(tester);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.byType(NewMatchSheet), findsNothing);
    expect(blocs.planned.state.matches, isEmpty);
  });

  testWidgets('dismissing an untouched sheet closes it without a prompt', (
    tester,
  ) async {
    final blocs = _blocs();

    await tester.pumpWidget(_app(blocs: blocs, home: _sheetOpener()));
    await _openSheet(tester);

    expect(find.byType(NewMatchSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Discard this match?'), findsNothing);
    expect(find.byType(NewMatchSheet), findsNothing);
  });

  testWidgets('dismissing a sheet with a score asks before discarding it', (
    tester,
  ) async {
    final blocs = _blocs();

    await tester.pumpWidget(_app(blocs: blocs, home: _sheetOpener()));
    await _openSheet(tester);

    await tester.enterText(find.byType(EditableText).first, '11');
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Discard this match?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.byType(NewMatchSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(NewMatchSheet), findsNothing);
  });

  testWidgets(
    'dismissing a sheet with a picked team asks before discarding it',
    (tester) async {
      final blocs = _blocs();

      await tester.pumpWidget(_app(blocs: blocs, home: _sheetOpener()));
      await _openSheet(tester);

      blocs.form.setTeam(MatchTeam.a, const ['p1']);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Discard this match?'), findsOneWidget);
    },
  );
}
