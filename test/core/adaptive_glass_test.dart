import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
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
        const AdaptiveGlass(
          opaqueFallback: Text('opaque'),
          child: Text('bar'),
        ),
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

    testWidgets('keeps its semantics label and fires on tap', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var taps = 0;
      await pumpGlass(tester, _floatingAction(() => taps++));

      expect(
        find.bySemanticsLabel('Add competition'),
        findsOneWidget,
      );

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

Widget _tabBar(ValueChanged<int> onTap) {
  return AdaptiveBottomTabBar(
    items: const [
      AdaptiveTabBarItem(glyph: AdaptiveGlyph.leaderboard, label: 'Ranking'),
      AdaptiveTabBarItem(glyph: AdaptiveGlyph.matches, label: 'Matches'),
    ],
    selectedIndex: 0,
    onTap: onTap,
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
      child: const Align(
        alignment: Alignment.topCenter,
        child: Text('tap me'),
      ),
    ),
    floatingAction: withFloatingAction
        ? const SizedBox(key: Key('fab'), width: 56, height: 56)
        : null,
    bottomBar: _tabBar((_) {}),
  );
}
