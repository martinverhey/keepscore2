import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/tournament/domain/bracket.model.dart';
import 'package:keepscore2/features/tournament/presentation/widgets/bracket_match_tile.dart';
import 'package:keepscore2/features/tournament/presentation/widgets/bracket_view.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

TournamentMatch _match(
  int round,
  int slot, {
  String? a,
  String? b,
  String? winner,
  int? scoreA,
  int? scoreB,
}) => TournamentMatch(
  id: 'm$round-$slot',
  tournamentId: 't1',
  round: round,
  slot: slot,
  playerA: a == null ? null : TournamentEntrant(playerId: a, displayName: a),
  playerB: b == null ? null : TournamentEntrant(playerId: b, displayName: b),
  winnerPlayerId: winner,
  scoreA: scoreA,
  scoreB: scoreB,
);

// Six players in an eight bracket: the top two seeds get the byes, the rest
// pair adjacently. This is the shape start_tournament writes.
Bracket _sixPlayerBracket() => Bracket.fromMatches([
  _match(1, 0, a: 'Ada', winner: 'Ada'),
  _match(1, 1, a: 'Bo', winner: 'Bo'),
  _match(1, 2, a: 'Cas', b: 'Dee'),
  _match(1, 3, a: 'Eli', b: 'Fay'),
  _match(2, 0, a: 'Ada', b: 'Bo'),
  _match(2, 1),
  _match(3, 0),
]);

Future<void> _pump(
  WidgetTester tester,
  Bracket bracket, {
  void Function(TournamentMatch match)? onSelect,
  String? myPlayerId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BracketView(
          bracket: bracket,
          onSelect: onSelect,
          myPlayerId: myPlayerId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TextStyle _name(WidgetTester tester, String displayName) =>
    tester.widget<Text>(find.text(displayName).first).style!;

Finder _tile(String id) => find.byWidgetPredicate(
  (widget) => widget is BracketMatchTile && widget.match.id == id,
);

void main() {
  testWidgets('renders every slot of the bracket', (tester) async {
    await _pump(tester, _sixPlayerBracket());

    expect(find.byType(BracketMatchTile), findsNWidgets(7));
  });

  testWidgets('names the last three rounds rather than numbering them', (
    tester,
  ) async {
    await _pump(tester, _sixPlayerBracket());

    expect(find.text('Quarter-finals'), findsOneWidget);
    expect(find.text('Semi-finals'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
    expect(find.text('Round 1'), findsNothing);
  });

  testWidgets('a slot with one player reads as a bye', (tester) async {
    await _pump(tester, _sixPlayerBracket());

    expect(
      find.descendant(of: _tile('m1-0'), matching: find.text('Bye')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _tile('m1-2'), matching: find.text('Bye')),
      findsNothing,
    );
  });

  testWidgets('an empty slot is waiting, not a bye', (tester) async {
    await _pump(tester, _sixPlayerBracket());

    expect(
      find.descendant(of: _tile('m3-0'), matching: find.text('Waiting')),
      findsNWidgets(2),
    );
  });

  testWidgets('a parent sits centred between the two slots feeding it', (
    tester,
  ) async {
    await _pump(tester, _sixPlayerBracket());

    final firstChild = tester.getRect(_tile('m1-0')).center.dy;
    final secondChild = tester.getRect(_tile('m1-1')).center.dy;
    final parent = tester.getRect(_tile('m2-0')).center.dy;

    expect(parent, closeTo((firstChild + secondChild) / 2, 0.5));
  });

  testWidgets('the final sits centred on the whole bracket', (tester) async {
    await _pump(tester, _sixPlayerBracket());

    final top = tester.getRect(_tile('m1-0')).center.dy;
    final bottom = tester.getRect(_tile('m1-3')).center.dy;
    final finalSlot = tester.getRect(_tile('m3-0')).center.dy;

    expect(finalSlot, closeTo((top + bottom) / 2, 0.5));
  });

  testWidgets('only a slot with both players is selectable', (tester) async {
    final selected = <String>[];
    await _pump(tester, _sixPlayerBracket(), onSelect: (m) => selected.add(m.id));

    await tester.tap(_tile('m1-2'));
    await tester.pumpAndSettle();
    expect(selected, ['m1-2']);

    await tester.tap(_tile('m2-1'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(selected, ['m1-2']);
  });

  testWidgets('a winner is bold, and only the viewer is accented', (
    tester,
  ) async {
    await _pump(
      tester,
      Bracket.fromMatches([
        _match(1, 0, a: 'Ada', b: 'Bo', winner: 'Bo'),
        _match(1, 1, a: 'Cas', b: 'Dee'),
        _match(2, 0),
      ]),
      myPlayerId: 'Dee',
    );

    final winner = _name(tester, 'Bo');
    final viewer = _name(tester, 'Dee');
    final loser = _name(tester, 'Ada');

    expect(winner.fontWeight, FontWeight.w700);
    expect(winner.color, loser.color);
    expect(viewer.fontWeight, FontWeight.w400);
    expect(viewer.color, isNot(loser.color));
  });

  testWidgets('a played slot shows both scores', (tester) async {
    await _pump(
      tester,
      Bracket.fromMatches([
        _match(1, 0, a: 'Ada', b: 'Bo', winner: 'Ada', scoreA: 21, scoreB: 15),
      ]),
    );

    expect(find.text('21'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
  });
}
