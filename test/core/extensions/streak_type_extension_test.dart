import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/extensions/streak_type.extension.dart';
import 'package:keepscore2/core/theme/app_theme.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/features/profile/domain/streak_type.enum.dart';

void main() {
  test('the ladder climbs at 5, 10, 25 and 50 games', () {
    expect([2, 3, 5, 10, 25, 49, 50, 120].map(StreakType.win.tier), [
      0,
      0,
      1,
      2,
      3,
      3,
      4,
      4,
    ]);
    expect(StreakType.none.tier(50), 0);
  });

  test('the glyphs climb to three, then the 50+ tier shows a single one', () {
    expect([5, 10, 25, 50].map(StreakType.loss.glyphCount), [1, 2, 3, 1]);
  });

  testWidgets('50 games turns elite, and the elite ice lightens on a dark '
      'surface', (tester) async {
    expect(await _colorsUnder(tester, Brightness.light), [
      AppColors.fireCore,
      AppColors.fireEliteCore,
      AppColors.fireEliteCore.withValues(alpha: AppOpacity.badgeFill),
      AppColors.iceEliteCore,
    ]);
    expect(await _colorsUnder(tester, Brightness.dark), [
      AppColors.fireCore,
      AppColors.fireEliteCore,
      AppColors.fireEliteCore.withValues(alpha: AppOpacity.badgeFill),
      AppColors.iceEliteCoreOnDark,
    ]);
  });
}

Future<List<Color>> _colorsUnder(
  WidgetTester tester,
  Brightness brightness,
) async {
  late List<Color> colors;
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey(brightness),
      theme: AppTheme.material(brightness),
      home: Builder(
        builder: (context) {
          colors = [
            StreakType.win.glyphColor(context, 25),
            StreakType.win.glyphColor(context, 50),
            StreakType.win.badgeFill(context, 50),
            StreakType.loss.glyphColor(context, 50),
          ];
          return const SizedBox();
        },
      ),
    ),
  );
  return colors;
}
