import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/match/domain/match_entry.model.dart';
import 'package:keepscore2/features/match/presentation/widgets/match_tile.dart';

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
          child: MatchTile(match: match, onTap: () {}),
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

  testWidgets('draws an accent rail on the side the player is on', (
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

    Future<Border?> pumpAndFindBorder(String? myPlayerId) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MatchTile(match: match, myPlayerId: myPlayerId, onTap: () {}),
        ),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      return (container.decoration! as BoxDecoration).border as Border?;
    }

    expect(await pumpAndFindBorder(null), isNull);

    final zoesBorder = await pumpAndFindBorder('Zoe');
    expect(zoesBorder!.left.width, 1);
    expect(zoesBorder.right, BorderSide.none);

    final theosBorder = await pumpAndFindBorder('Theo');
    expect(theosBorder!.right.width, 1);
    expect(theosBorder.left, BorderSide.none);

    expect(tester.takeException(), isNull);
  });
}
