import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/presentation/pages/match_score_sheet.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

MatchEntry _match({required bool oneVsOne}) => MatchEntry(
  id: 'm1',
  competitionId: 'c1',
  seasonId: 's1',
  playedAt: DateTime(2026, 8, 9),
  teamAScore: 11,
  teamBScore: 7,
  teamARating: 1000,
  teamBRating: 1000,
  teamA: [
    const MatchParticipant(
      playerId: 'p1',
      displayName: 'Ada',
      ratingBefore: 1000,
      ratingDelta: 8,
    ),
    if (!oneVsOne)
      const MatchParticipant(
        playerId: 'p2',
        displayName: 'Grace',
        ratingBefore: 1000,
        ratingDelta: 8,
      ),
  ],
  teamB: [
    const MatchParticipant(
      playerId: 'p3',
      displayName: 'Zoe',
      ratingBefore: 1000,
      ratingDelta: -8,
    ),
  ],
);

Future<void> _pump(WidgetTester tester, {required bool oneVsOne}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(child: MatchScoreSheet(match: _match(oneVsOne: oneVsOne))),
    ),
  );
}

void main() {
  testWidgets('a 1v1 match names its sides after the players', (tester) async {
    await _pump(tester, oneVsOne: true);
    await tester.pumpAndSettle();

    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
  });

  testWidgets('a match with a bigger side names its sides after the teams', (
    tester,
  ) async {
    await _pump(tester, oneVsOne: false);
    await tester.pumpAndSettle();

    expect(find.text('Team 1'), findsOneWidget);
    expect(find.text('Team 2'), findsOneWidget);
  });
}
