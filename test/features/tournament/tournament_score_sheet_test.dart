import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/tournament/domain/bracket.model.dart';
import 'package:keepscore2/features/tournament/presentation/pages/tournament_score_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

TournamentMatch _match({int? scoreA, int? scoreB}) => TournamentMatch(
  id: 'm1-0',
  tournamentId: 't1',
  round: 1,
  slot: 0,
  playerA: const TournamentEntrant(playerId: 'p1', displayName: 'Ada'),
  playerB: const TournamentEntrant(playerId: 'p2', displayName: 'Bo'),
  scoreA: scoreA,
  scoreB: scoreB,
);

Future<void> _pump(WidgetTester tester, TournamentMatch match) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TournamentScoreSheet(match: match)),
    ),
  );
  await tester.pumpAndSettle();
}

AdaptiveButton _saveButton(WidgetTester tester) =>
    tester.widget<AdaptiveButton>(
      find.widgetWithText(AdaptiveButton, 'Save result'),
    );

Future<void> _enter(WidgetTester tester, String name, String value) async {
  await tester.enterText(find.widgetWithText(AdaptiveTextField, name), value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('both players are already named on their own field', (
    tester,
  ) async {
    await _pump(tester, _match());

    expect(find.widgetWithText(AdaptiveTextField, 'Ada'), findsOneWidget);
    expect(find.widgetWithText(AdaptiveTextField, 'Bo'), findsOneWidget);
  });

  testWidgets('an already-played slot opens with its scores filled in', (
    tester,
  ) async {
    await _pump(tester, _match(scoreA: 21, scoreB: 15));

    expect(find.text('21'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('Save is refused until both scores are there', (tester) async {
    await _pump(tester, _match());

    expect(_saveButton(tester).onPressed, isNull);

    await _enter(tester, 'Ada', '21');
    expect(_saveButton(tester).onPressed, isNull);

    await _enter(tester, 'Bo', '15');
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a draw is refused, and the sheet says why', (tester) async {
    await _pump(tester, _match());

    await _enter(tester, 'Ada', '11');
    await _enter(tester, 'Bo', '11');

    expect(_saveButton(tester).onPressed, isNull);
    expect(find.text('A tournament match needs a winner.'), findsOneWidget);
  });

  testWidgets('saving pops the two scores', (tester) async {
    (int, int)? result;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showTournamentScoreSheet(
                    context,
                    match: _match(),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await _enter(tester, 'Ada', '21');
    await _enter(tester, 'Bo', '15');
    await tester.tap(find.widgetWithText(AdaptiveButton, 'Save result'));
    await tester.pumpAndSettle();

    expect(result, (21, 15));
  });
}
