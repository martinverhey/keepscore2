import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/theme/app_theme.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (max(first, second) + 0.05) / (min(first, second) + 0.05);
}

Future<List<Color>> resolvedUnder(WidgetTester tester, Brightness b) async {
  late List<Color> colors;
  final probe = Builder(
    builder: (context) {
      colors = [
        AdaptiveColors.accent(context),
        AdaptiveColors.teamA(context),
        AdaptiveColors.teamB(context),
      ];
      return const SizedBox();
    },
  );

  final key = ValueKey('$b-${AppPlatform.useCupertino}');
  await tester.pumpWidget(
    AppPlatform.useCupertino
        ? CupertinoApp(key: key, theme: AppTheme.cupertino(b), home: probe)
        : MaterialApp(key: key, theme: AppTheme.material(b), home: probe),
  );
  return colors;
}

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  testWidgets('the accent swaps for a dark surface on either platform', (
    tester,
  ) async {
    for (final cupertino in [false, true]) {
      AppPlatform.debugOverrideCupertino = cupertino;

      expect(
        await resolvedUnder(tester, Brightness.light),
        [AppColors.seed, AppColors.teamA, AppColors.teamB],
        reason: 'useCupertino=$cupertino',
      );

      expect(
        await resolvedUnder(tester, Brightness.dark),
        [AppColors.seedOnDark, AppColors.teamAOnDark, AppColors.teamBOnDark],
        reason: 'useCupertino=$cupertino',
      );
    }
  });

  test('both palettes clear 4.5:1 against the surface they are drawn on', () {
    for (final brightness in Brightness.values) {
      final surface = AppTheme.material(brightness).colorScheme.surface;
      final dark = brightness == Brightness.dark;

      final inks = {
        'accent': dark ? AppColors.seedOnDark : AppColors.seed,
        'teamA': dark ? AppColors.teamAOnDark : AppColors.teamA,
        'teamB': dark ? AppColors.teamBOnDark : AppColors.teamB,
      };

      inks.forEach((name, ink) {
        expect(
          contrast(ink, surface),
          greaterThan(4.5),
          reason: '$name on the $brightness surface',
        );
      });
    }
  });
}
