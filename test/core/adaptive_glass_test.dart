import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';

Future<void> pumpGlass(
  WidgetTester tester,
  Widget child, {
  bool highContrast = false,
}) {
  return tester.pumpWidget(
    CupertinoApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(highContrast: highContrast),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  tearDown(() {
    AppPlatform.debugOverrideLiquidGlass = null;
    AppPlatform.debugOverrideCupertino = null;
  });

  group('AppPlatform.useLiquidGlass', () {
    test('is off under flutter test unless a test opts in', () {
      expect(AppPlatform.useLiquidGlass, isFalse);
    });

    test('does not follow the Cupertino override', () {
      AppPlatform.debugOverrideCupertino = true;
      expect(AppPlatform.useLiquidGlass, isFalse);
    });

    test('honours its own override in both directions', () {
      AppPlatform.debugOverrideLiquidGlass = true;
      expect(AppPlatform.useLiquidGlass, isTrue);

      AppPlatform.debugOverrideLiquidGlass = false;
      expect(AppPlatform.useLiquidGlass, isFalse);
    });
  });

  group('AdaptiveGlass', () {
    testWidgets('renders a lens when glass is on', (tester) async {
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, const AdaptiveGlass(child: Text('bar')));

      expect(find.byType(LiquidGlassLens), findsOneWidget);
      expect(find.text('bar'), findsOneWidget);
    });

    testWidgets('renders the child bare when glass is off', (tester) async {
      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(tester, const AdaptiveGlass(child: Text('bar')));

      expect(find.byType(LiquidGlassLens), findsNothing);
      expect(find.text('bar'), findsOneWidget);
    });

    testWidgets('prefers the opaque fallback when glass is off', (
      tester,
    ) async {
      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(
        tester,
        const AdaptiveGlass(opaqueFallback: Text('opaque'), child: Text('bar')),
      );

      expect(find.text('opaque'), findsOneWidget);
      expect(find.text('bar'), findsNothing);
    });

    testWidgets('falls back to opaque under Increase Contrast', (tester) async {
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(
        tester,
        const AdaptiveGlass(child: Text('bar')),
        highContrast: true,
      );

      expect(find.byType(LiquidGlassLens), findsNothing);
      expect(find.text('bar'), findsOneWidget);
    });

    testWidgets('warms up without throwing when glass is off', (tester) async {
      AppPlatform.debugOverrideLiquidGlass = false;
      await expectLater(AdaptiveGlass.warmUp(), completes);
    });
  });

  group('AdaptiveBottomTabBar', () {
    testWidgets('renders a glass bar on iOS and a CupertinoTabBar without', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _tabBar((_) {}));

      expect(find.byType(LiquidGlassTabBar), findsOneWidget);
      expect(find.byType(CupertinoTabBar), findsNothing);

      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(tester, _tabBar((_) {}));

      expect(find.byType(LiquidGlassTabBar), findsNothing);
      expect(find.byType(CupertinoTabBar), findsOneWidget);
    });

    testWidgets('splits the action out of the glass capsule', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var actions = 0;
      final tapped = <int>[];
      await pumpGlass(tester, _tabBar(tapped.add, onNewMatch: () => actions++));

      expect(find.byType(LiquidGlassTabBarAction), findsOneWidget);

      await tester.tap(find.byType(LiquidGlassTabBarAction));
      await tester.pumpAndSettle();

      expect(actions, 1);
      expect(tapped, isEmpty);
    });

    testWidgets('has no action button when none is given', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _tabBar((_) {}));

      expect(find.byType(LiquidGlassTabBarAction), findsNothing);
    });

    testWidgets('trails the action as an item without glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = false;
      var actions = 0;
      final tapped = <int>[];
      await pumpGlass(tester, _tabBar(tapped.add, onNewMatch: () => actions++));

      await tester.tap(find.text('New match'));
      await tester.pumpAndSettle();

      expect(actions, 1);
      expect(tapped, isEmpty);

      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      expect(tapped, [1]);
    });

    testWidgets('keeps its own tab highlighted when a tap navigates away', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _tabBar((_) {}));

      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      expect(_isHighlighted(tester, AdaptiveGlyph.leaderboard), isTrue);
      expect(_isHighlighted(tester, AdaptiveGlyph.matches), isFalse);
    });

    testWidgets('reseeds the glass bar when a tap navigates away', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _tabBar((_) {}, onNewMatch: () {}));

      final before = _glassBarKey(tester);

      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      expect(_glassBarKey(tester), isNot(before));
    });

    testWidgets('leaves the glass bar alone for taps that do not move it', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _tabBar((_) {}, onNewMatch: () {}));

      final before = _glassBarKey(tester);

      await tester.tap(find.text('Ranking'));
      await tester.pumpAndSettle();
      expect(_glassBarKey(tester), before);

      await tester.tap(find.byType(LiquidGlassTabBarAction));
      await tester.pumpAndSettle();
      expect(_glassBarKey(tester), before);
    });

    testWidgets('reports the tapped index from the glass bar', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      final tapped = <int>[];
      await pumpGlass(tester, _tabBar(tapped.add));

      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      expect(tapped, [1]);
    });
  });

  group('AdaptiveFloatingAction', () {
    testWidgets('renders a glass fab on iOS and a plain button without', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _floatingAction(() {}));

      expect(find.byType(LiquidGlassFab), findsOneWidget);
      expect(find.byType(CupertinoButton), findsNothing);

      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(tester, _floatingAction(() {}));

      expect(find.byType(LiquidGlassFab), findsNothing);
      expect(find.byType(CupertinoButton), findsOneWidget);
    });

    testWidgets('keeps the untinted package default glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _floatingAction(() {}));

      expect(
        tester.widget<LiquidGlassFab>(find.byType(LiquidGlassFab)).style,
        isNull,
      );
    });

    testWidgets('paints its glyph in the label colour, not the accent', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _floatingAction(() {}));

      expect(
        tester
            .widget<AdaptiveIcon>(
              find.descendant(
                of: find.byType(LiquidGlassFab),
                matching: find.byType(AdaptiveIcon),
              ),
            )
            .color,
        AppColors.black,
      );
    });

    testWidgets('keeps its semantics label and fires on tap', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var taps = 0;
      await pumpGlass(tester, _floatingAction(() => taps++));

      expect(find.bySemanticsLabel('Add competition'), findsOneWidget);

      await tester.tap(find.byType(LiquidGlassFab));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('shows the loader and refuses taps while busy', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var taps = 0;
      await pumpGlass(tester, _floatingAction(() => taps++, busy: true));

      expect(find.byType(AdaptiveLoader), findsOneWidget);

      await tester.tap(find.byType(LiquidGlassFab));
      await tester.pump();

      expect(taps, 0);
    });
  });

  group('AdaptiveScaffold under a floating glass bar', () {
    testWidgets('leaves room below the body for the bar', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold());

      final height = tester.getSize(find.byType(CupertinoPageScaffold)).height;
      expect(
        tester.getRect(find.byKey(const Key('body'))).bottom,
        lessThanOrEqualTo(height - AdaptiveScaffold.glassBarInset),
      );
    });

    testWidgets('lifts the floating action above the bar', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold(withFloatingAction: true));

      final height = tester.getSize(find.byType(CupertinoPageScaffold)).height;
      expect(
        tester.getRect(find.byKey(const Key('fab'))).bottom,
        lessThanOrEqualTo(height - AdaptiveScaffold.glassBarInset),
      );
    });

    testWidgets('lets taps through to the content under the overlay', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var taps = 0;
      await pumpGlass(tester, _scaffold(onBodyTap: () => taps++));

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}

Key? _glassBarKey(WidgetTester tester) {
  return tester.widget<LiquidGlassTabBar>(find.byType(LiquidGlassTabBar)).key;
}

bool _isHighlighted(WidgetTester tester, AdaptiveGlyph glyph) {
  return tester
      .widgetList<AdaptiveIcon>(find.byType(AdaptiveIcon))
      .any((icon) => icon.glyph == glyph && icon.color == AppColors.seed);
}

Widget _tabBar(ValueChanged<int> onTap, {VoidCallback? onNewMatch}) {
  return AdaptiveBottomTabBar(
    items: const [
      AdaptiveTabBarItem(glyph: AdaptiveGlyph.leaderboard, label: 'Ranking'),
      AdaptiveTabBarItem(glyph: AdaptiveGlyph.matches, label: 'Matches'),
    ],
    selectedIndex: 0,
    onTap: onTap,
    action: onNewMatch == null
        ? null
        : AdaptiveTabBarAction(
            glyph: AdaptiveGlyph.newMatch,
            label: 'New match',
            onPressed: onNewMatch,
          ),
  );
}

Widget _floatingAction(VoidCallback onPressed, {bool busy = false}) {
  return Center(
    child: AdaptiveFloatingAction(
      glyph: AdaptiveGlyph.add,
      onPressed: onPressed,
      semanticLabel: 'Add competition',
      busy: busy,
    ),
  );
}

Widget _scaffold({bool withFloatingAction = false, VoidCallback? onBodyTap}) {
  return AdaptiveScaffold(
    title: 'Leaderboard',
    body: GestureDetector(
      key: const Key('body'),
      onTap: onBodyTap,
      child: const Align(alignment: Alignment.topCenter, child: Text('tap me')),
    ),
    floatingAction: withFloatingAction
        ? const SizedBox(key: Key('fab'), width: 56, height: 56)
        : null,
    bottomBar: _tabBar((_) {}),
  );
}
