import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/core/widgets/streak_badge.dart';
import 'package:keepscore2/features/profile/domain/streak_type.enum.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

void main() {
  testWidgets('a badge with several glyphs overlaps them', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Center(child: StreakBadge(type: StreakType.win, count: 25)),
      ),
    );

    final glyphs = tester
        .widgetList(find.byType(AdaptiveIcon))
        .map((glyph) => tester.getRect(find.byWidget(glyph)))
        .toList();

    expect(glyphs, hasLength(3));
    for (var i = 1; i < glyphs.length; i++) {
      expect(glyphs[i].left, lessThan(glyphs[i - 1].right));
    }
    expect(tester.takeException(), isNull);
  });
}
