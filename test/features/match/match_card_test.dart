import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/presentation/widgets/match_card.dart';

MatchParticipant _participant(String name) => MatchParticipant(
  playerId: name,
  displayName: name,
  ratingBefore: 1000,
  ratingDelta: 12,
);

void main() {
  testWidgets('a long player name is truncated to a single line', (
    tester,
  ) async {
    final match = MatchEntry(
      id: 'm1',
      competitionId: 'c1',
      seasonId: 's1',
      playedAt: DateTime(2026, 8, 1),
      teamAScore: 11,
      teamBScore: 7,
      teamARating: 1000,
      teamBRating: 1000,
      teamA: [_participant('Bartholomew Alexandertonovich')],
      teamB: [_participant('Zoe')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          child: MatchCard(match: match, onTap: () {}),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.text('Bartholomew Alexandertonovich'),
    );

    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the viewer\'s own name is accented, everyone else is neutral', (
    tester,
  ) async {
    final match = MatchEntry(
      id: 'm1',
      competitionId: 'c1',
      seasonId: 's1',
      playedAt: DateTime(2026, 8, 1),
      teamAScore: 7,
      teamBScore: 11,
      teamARating: 1000,
      teamBRating: 1000,
      teamA: [_participant('Zoe')],
      teamB: [_participant('Theo')],
    );

    late BuildContext cardContext;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            cardContext = context;
            return MatchCard(match: match, myPlayerId: 'Zoe');
          },
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Zoe')).style!.color,
      AdaptiveColors.accent(cardContext),
    );
    expect(
      tester.widget<Text>(find.text('Theo')).style!.color,
      AppColors.neutral,
    );
    expect(tester.takeException(), isNull);
  });
}
