import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

Future<void> _pumpGlassAction(
  WidgetTester tester, {
  required bool active,
}) async {
  AppPlatform.debugOverrideLiquidGlass = true;
  await tester.pumpWidget(
    CupertinoApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AdaptiveBarAction(
        glyph: AdaptiveGlyph.filter,
        active: active,
        onPressed: () {},
      ),
    ),
  );
}

Color? _glyphColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byType(Icon)).color;

Color? _lensTint(WidgetTester tester) => tester
    .widget<LiquidGlassTabBarAction>(find.byType(LiquidGlassTabBarAction))
    .style!
    .appearance
    .color;

Future<Color?> _pumpAndReadGlyphColor(
  WidgetTester tester, {
  required bool active,
  required bool useCupertino,
}) async {
  AppPlatform.debugOverrideLiquidGlass = false;
  AppPlatform.debugOverrideCupertino = useCupertino;
  final action = AdaptiveBarAction(
    glyph: AdaptiveGlyph.filter,
    active: active,
    onPressed: () {},
  );
  await tester.pumpWidget(
    useCupertino
        ? CupertinoApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: action,
          )
        : MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: action,
          ),
  );

  return _glyphColor(tester);
}

void main() {
  tearDown(() {
    AppPlatform.debugOverrideLiquidGlass = null;
    AppPlatform.debugOverrideCupertino = null;
  });

  testWidgets('an active glass action paints its glyph in the accent', (
    tester,
  ) async {
    await _pumpGlassAction(tester, active: true);

    expect(_glyphColor(tester), AppColors.seed);
  });

  testWidgets('an inactive glass action keeps the neutral glyph', (
    tester,
  ) async {
    await _pumpGlassAction(tester, active: false);

    expect(_glyphColor(tester), AppColors.black);
  });

  testWidgets('an active glass action leaves the lens itself untinted', (
    tester,
  ) async {
    await _pumpGlassAction(tester, active: true);
    final active = _lensTint(tester);

    await _pumpGlassAction(tester, active: false);

    expect(active, _lensTint(tester));
    expect(active, LiquidGlassTabBarAction.defaultStyle.appearance.color);
  });

  for (final useCupertino in [false, true]) {
    testWidgets(
      'an active action paints its glyph in the accent off glass '
      '(cupertino: $useCupertino)',
      (tester) async {
        expect(
          await _pumpAndReadGlyphColor(
            tester,
            active: true,
            useCupertino: useCupertino,
          ),
          AppColors.seed,
        );

        expect(
          await _pumpAndReadGlyphColor(
            tester,
            active: false,
            useCupertino: useCupertino,
          ),
          isNull,
        );
      },
    );
  }
}
