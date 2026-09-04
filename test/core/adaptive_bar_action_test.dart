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

Future<void> _pumpGroup(
  WidgetTester tester, {
  required bool glass,
  required int actionCount,
}) async {
  AppPlatform.debugOverrideLiquidGlass = glass;
  await tester.pumpWidget(
    CupertinoApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AdaptiveBarActionGroup(
        actions: [
          for (var index = 0; index < actionCount; index++)
            AdaptiveBarAction(glyph: AdaptiveGlyph.filter, onPressed: () {}),
        ],
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

  testWidgets('an active glass action leaves the lens body unchanged', (
    tester,
  ) async {
    await _pumpGlassAction(tester, active: true);
    final active = _lensTint(tester);

    await _pumpGlassAction(tester, active: false);

    expect(active, _lensTint(tester));
    expect(active, AppColors.glassActionTint);
  });

  testWidgets('two glass actions share one capsule', (tester) async {
    await _pumpGroup(tester, glass: true, actionCount: 2);

    expect(find.byType(LiquidGlassLens), findsOneWidget);
    expect(find.byType(LiquidGlassTabBarAction), findsNothing);
    expect(find.byType(Icon), findsNWidgets(2));
  });

  testWidgets('a capsule still hands taps to each action', (tester) async {
    final tapped = <int>[];
    AppPlatform.debugOverrideLiquidGlass = true;
    AppPlatform.debugOverrideCupertino = true;
    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Center(
          child: AdaptiveBarActionGroup(
            actions: [
              for (var index = 0; index < 2; index++)
                AdaptiveBarAction(
                  glyph: AdaptiveGlyph.filter,
                  semanticLabel: 'action $index',
                  onPressed: () => tapped.add(index),
                ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('action 1'));

    expect(tapped, [1]);
  });

  testWidgets('a labelled glass action is a lens around its text', (
    tester,
  ) async {
    AppPlatform.debugOverrideLiquidGlass = true;
    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AdaptiveBarAction(label: 'Join', onPressed: () {}),
      ),
    );

    expect(find.text('Join'), findsOneWidget);
    expect(find.byType(LiquidGlassLens), findsOneWidget);
    expect(find.byType(LiquidGlassTabBarAction), findsNothing);
  });

  testWidgets('a labelled glass action splashes like a glyph one', (
    tester,
  ) async {
    AppPlatform.debugOverrideLiquidGlass = true;
    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AdaptiveBarAction(label: 'Join', onPressed: () {}),
      ),
    );

    expect(
      tester.widget<InkWell>(find.byType(InkWell)).customBorder,
      const StadiumBorder(),
    );
  });

  testWidgets('a capsuled glyph splashes inside its own circle', (
    tester,
  ) async {
    await _pumpGroup(tester, glass: true, actionCount: 2);

    expect(
      tester.widgetList<InkWell>(find.byType(InkWell)).map(
        (action) => action.customBorder,
      ),
      everyElement(const CircleBorder()),
    );
  });

  testWidgets('a labelled action off glass is a plain text button', (
    tester,
  ) async {
    AppPlatform.debugOverrideLiquidGlass = false;
    AppPlatform.debugOverrideCupertino = false;
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Center(
          child: AdaptiveBarAction(label: 'Join', onPressed: () => taps++),
        ),
      ),
    );

    expect(find.byType(TextButton), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.text('Join'));

    expect(taps, 1);
  });

  testWidgets('a labelled action is not capsuled with a glyph one', (
    tester,
  ) async {
    AppPlatform.debugOverrideLiquidGlass = true;
    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AdaptiveBarActionGroup(
          actions: [
            AdaptiveBarAction(glyph: AdaptiveGlyph.add, onPressed: () {}),
            AdaptiveBarAction(label: 'Join', onPressed: () {}),
          ],
        ),
      ),
    );

    expect(find.byType(LiquidGlassTabBarAction), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
  });

  testWidgets('a lone glass action keeps its own lens', (tester) async {
    await _pumpGroup(tester, glass: true, actionCount: 1);

    expect(find.byType(LiquidGlassTabBarAction), findsOneWidget);
  });

  testWidgets('actions off glass get no capsule', (tester) async {
    AppPlatform.debugOverrideCupertino = true;
    await _pumpGroup(tester, glass: false, actionCount: 2);

    expect(find.byType(LiquidGlassLens), findsNothing);
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
