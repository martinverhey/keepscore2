import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/core/widgets/selectable_row.dart';
import 'package:keepscore2/features/player/domain/player.model.dart';
import 'package:keepscore2/features/player/domain/player_repository.dart';
import 'package:keepscore2/features/tournament/domain/tournament_repository.dart';
import 'package:keepscore2/features/tournament/presentation/cubit/start_tournament_cubit.dart';
import 'package:keepscore2/features/tournament/presentation/pages/start_tournament_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

const _competitionId = 'c1';

List<Player> _roster(int count) => [
  for (var i = 0; i < count; i++)
    Player(
      id: 'p$i',
      competitionId: _competitionId,
      displayName: 'Player $i',
      isActive: true,
    ),
];

Future<MockTournamentRepository> _pump(
  WidgetTester tester, {
  int players = 6,
  List<Player>? roster,
  String? myPlayerId,
}) async {
  final playerRepository = MockPlayerRepository();
  final tournaments = MockTournamentRepository();

  when(
    () => playerRepository.currentPlayers(_competitionId),
  ).thenAnswer((_) async => roster ?? _roster(players));

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) =>
            StartTournamentCubit(tournaments, playerRepository, _competitionId)
              ..load(),
        child: Scaffold(
          body: StartTournamentSheet(myPlayerId: myPlayerId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tournaments;
}

AdaptiveButton _startButton(WidgetTester tester) => tester.widget<AdaptiveButton>(
  find.widgetWithText(AdaptiveButton, 'Start tournament'),
);

Future<void> _select(WidgetTester tester, String name) async {
  final row = find.widgetWithText(SelectableRow, name);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Finder _row(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(SelectableRow));

void main() {
  testWidgets('the roster reads like the player picker', (tester) async {
    await _pump(
      tester,
      roster: [
        Player(
          id: 'p1',
          competitionId: _competitionId,
          displayName: 'Zoe',
          isActive: true,
        ),
        Player(
          id: 'p2',
          competitionId: _competitionId,
          displayName: 'Ada',
          isActive: true,
        ),
        Player(
          id: 'p3',
          competitionId: _competitionId,
          displayName: 'Mia',
          isActive: true,
        ),
      ],
      myPlayerId: 'p2',
    );

    final tops = [
      for (final name in ['Ada', 'Mia', 'Zoe']) tester.getRect(_row(name)).top,
    ];

    expect(tops, equals(List.of(tops)..sort()));
    expect(tester.widget<SelectableRow>(_row('Ada')).labelColor, isNotNull);
    expect(tester.widget<SelectableRow>(_row('Zoe')).labelColor, isNull);
  });

  testWidgets('Start only opens on a bracket-sized field', (tester) async {
    await _pump(tester, players: 9);

    expect(_startButton(tester).onPressed, isNull);

    await _select(tester, 'Player 0');
    expect(_startButton(tester).onPressed, isNull);

    await _select(tester, 'Player 1');
    expect(_startButton(tester).onPressed, isNotNull);

    await _select(tester, 'Player 2');
    expect(_startButton(tester).onPressed, isNull);

    await _select(tester, 'Player 3');
    expect(_startButton(tester).onPressed, isNotNull);

    for (final index in [4, 5, 6]) {
      await _select(tester, 'Player $index');
      expect(_startButton(tester).onPressed, isNull);
    }

    await _select(tester, 'Player 7');
    expect(_startButton(tester).onPressed, isNotNull);

    await _select(tester, 'Player 8');
    expect(_startButton(tester).onPressed, isNull);
  });

  testWidgets('the sheet says which field sizes make a bracket', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      find.text(
        'Pick 2, 4, 8 or 16 players. The closest-rated players meet first.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the header counts what is selected', (tester) async {
    await _pump(tester);

    expect(find.text('0 of 16 selected'), findsOneWidget);

    await _select(tester, 'Player 0');
    expect(find.text('1 of 16 selected'), findsOneWidget);
  });

  testWidgets('deselecting a player puts them back', (tester) async {
    await _pump(tester);

    await _select(tester, 'Player 0');
    await _select(tester, 'Player 0');

    expect(find.text('0 of 16 selected'), findsOneWidget);
    expect(_startButton(tester).onPressed, isNull);
  });

  testWidgets('the seventeenth player cannot be added', (tester) async {
    await _pump(tester, players: 17);

    for (var i = 0; i < 16; i++) {
      await _select(tester, 'Player $i');
    }
    expect(find.text('16 of 16 selected'), findsOneWidget);

    await _select(tester, 'Player 16');

    expect(find.text('16 of 16 selected'), findsOneWidget);
    final row = tester.widget<SelectableRow>(
      find.widgetWithText(SelectableRow, 'Player 16'),
    );
    expect(row.selected, isFalse);
  });

  testWidgets('starting hands the picked ids to the repository', (
    tester,
  ) async {
    final tournaments = await _pump(tester);
    when(
      () => tournaments.start(
        competitionId: any(named: 'competitionId'),
        playerIds: any(named: 'playerIds'),
      ),
    ).thenAnswer((_) async => 't1');

    await _select(tester, 'Player 0');
    await _select(tester, 'Player 2');
    await tester.tap(find.widgetWithText(AdaptiveButton, 'Start tournament'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => tournaments.start(
        competitionId: _competitionId,
        playerIds: captureAny(named: 'playerIds'),
      ),
    ).captured.single as List<String>;

    expect(captured, ['p0', 'p2']);
  });

  testWidgets('a refused start is shown and the sheet stays open', (
    tester,
  ) async {
    final tournaments = await _pump(tester);
    when(
      () => tournaments.start(
        competitionId: any(named: 'competitionId'),
        playerIds: any(named: 'playerIds'),
      ),
    ).thenThrow(
      const ValidationFailure('This competition already has a tournament running'),
    );

    await _select(tester, 'Player 0');
    await _select(tester, 'Player 1');
    await tester.tap(find.widgetWithText(AdaptiveButton, 'Start tournament'));
    await tester.pumpAndSettle();

    expect(
      find.text('This competition already has a tournament running'),
      findsOneWidget,
    );
    expect(find.byType(StartTournamentSheet), findsOneWidget);
  });

  testWidgets('an empty roster says players will show up here', (tester) async {
    await _pump(tester, roster: const []);

    expect(find.text('Players will show up here.'), findsOneWidget);
  });
}
