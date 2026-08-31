import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

LiquidGlassShape _rimOf(WidgetTester tester) {
  return tester
      .widget<LiquidGlassTabBarAction>(find.byType(LiquidGlassTabBarAction))
      .style!
      .shape!;
}

Future<void> pumpGlass(
  WidgetTester tester,
  Widget child, {
  bool highContrast = false,
  bool dark = false,
}) {
  return tester.pumpWidget(
    CupertinoApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: CupertinoThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
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

    testWidgets('renders the action beside the glass capsule', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var actions = 0;
      await pumpGlass(
        tester,
        _host(child: const SizedBox(), onNewMatch: () => actions++),
      );

      expect(find.byType(LiquidGlassTabBarAction), findsOneWidget);

      await tester.tap(find.byType(LiquidGlassTabBarAction));
      await tester.pumpAndSettle();

      expect(actions, 1);
    });

    testWidgets('renders the action as a fab without glass', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideLiquidGlass = false;
      var actions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: _host(child: const SizedBox(), onNewMatch: () => actions++),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New match'), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(actions, 1);
    });

    testWidgets('follows selectedIndex without remounting the bar', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, const _SwitchingTabBar());

      expect(_isHighlighted(tester, AdaptiveGlyph.leaderboard), isTrue);
      final element = tester.element(find.byType(LiquidGlassTabBar));

      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      expect(_isHighlighted(tester, AdaptiveGlyph.matches), isTrue);
      expect(_isHighlighted(tester, AdaptiveGlyph.leaderboard), isFalse);
      expect(tester.element(find.byType(LiquidGlassTabBar)), same(element));
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
    testWidgets('renders a glass action on iOS and a plain button without', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _floatingAction(() {}));

      expect(find.byType(LiquidGlassTabBarAction), findsOneWidget);
      expect(find.byType(CupertinoButton), findsNothing);

      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(tester, _floatingAction(() {}));

      expect(find.byType(LiquidGlassTabBarAction), findsNothing);
      expect(find.byType(CupertinoButton), findsOneWidget);
    });

    testWidgets('keeps the untinted package appearance', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _floatingAction(() {}));

      expect(
        tester
            .widget<LiquidGlassTabBarAction>(
              find.byType(LiquidGlassTabBarAction),
            )
            .style
            ?.appearance,
        LiquidGlassTabBarAction.defaultStyle.appearance,
      );
    });

    testWidgets('softens its rim in dark mode', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;

      await pumpGlass(tester, _floatingAction(() {}), dark: true);
      final darkRim = _rimOf(tester);

      await pumpGlass(tester, _floatingAction(() {}));
      final lightRim = _rimOf(tester);

      expect(darkRim.lightIntensity, lessThan(lightRim.lightIntensity));
      expect(darkRim.lightColor.a, lessThan(lightRim.lightColor.a));
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
                of: find.byType(LiquidGlassTabBarAction),
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

      await tester.tap(find.byType(LiquidGlassTabBarAction));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('shows the loader and refuses taps while busy', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var taps = 0;
      await pumpGlass(tester, _floatingAction(() => taps++, busy: true));

      expect(find.byType(AdaptiveLoader), findsOneWidget);

      await tester.tap(find.byType(LiquidGlassTabBarAction));
      await tester.pump();

      expect(taps, 0);
    });
  });

  group('AdaptiveBottomBarHost without glass', () {
    testWidgets('takes the bottom padding the bar covers off the page', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideLiquidGlass = false;

      await _pumpInset(tester, _host(child: _paddingProbe()));

      expect(_probedPadding.bottom, 0);
    });

    testWidgets('leaves the page padding alone with no bar', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideLiquidGlass = false;

      await _pumpInset(tester, _host(child: _paddingProbe(), withBar: false));

      expect(_probedPadding.bottom, 34);
    });

    testWidgets('adds no height of its own to the opaque bar', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideLiquidGlass = false;

      await _pumpInset(tester, _host(child: const SizedBox()));
      final hosted = tester.getSize(find.byType(NavigationBar)).height;

      await _pumpInset(tester, Scaffold(bottomNavigationBar: _tabBar((_) {})));
      final scaffolded = tester.getSize(find.byType(NavigationBar)).height;

      expect(hosted, scaffolded);
    });
  });

  group('showAdaptiveSheet', () {
    testWidgets('puts the iOS sheet on glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await _openSheet(tester);

      expect(find.byType(LiquidGlassLens), findsOneWidget);
      expect(find.text('sheet body'), findsOneWidget);
    });

    testWidgets('keeps the sheet opaque without glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = false;
      await _openSheet(tester);

      expect(find.byType(LiquidGlassLens), findsNothing);
      expect(find.text('sheet body'), findsOneWidget);
    });

    testWidgets('still guards dismissal on a glass sheet', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await _openSheet(tester, guarded: true);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('sheet body'), findsOneWidget);
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
        lessThanOrEqualTo(height - AdaptiveBottomBarHost.glassInset),
      );
    });

    testWidgets('lifts the floating action above the bar', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold(withFloatingAction: true));

      final height = tester.getSize(find.byType(CupertinoPageScaffold)).height;
      expect(
        tester.getRect(find.byKey(const Key('fab'))).bottom,
        lessThanOrEqualTo(height - AdaptiveBottomBarHost.glassInset),
      );
    });

    testWidgets('dims both scroll edges, on glass only', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold());

      expect(_scrollEdges(tester), {
        LiquidGlassEdge.top,
        LiquidGlassEdge.bottom,
      });

      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(tester, _scaffold());

      expect(find.byType(LiquidGlassScrollEdge), findsNothing);
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

  group('AdaptiveBarAction', () {
    testWidgets('is a glass circle on iOS and a plain icon button without', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _barAction());

      expect(find.byType(LiquidGlassTabBarAction), findsOneWidget);
      expect(find.byType(AdaptiveIconButton), findsNothing);

      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(tester, _barAction());

      expect(find.byType(LiquidGlassTabBarAction), findsNothing);
      expect(find.byType(AdaptiveIconButton), findsOneWidget);
    });

    testWidgets('paints its glyph in the label colour, not the accent', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _barAction());

      expect(_glyphColour(tester, AdaptiveGlyph.settings), AppColors.black);

      await pumpGlass(tester, _barAction(), dark: true);

      expect(_glyphColour(tester, AdaptiveGlyph.settings), AppColors.white);
    });
  });

  group('AdaptiveSwitch', () {
    testWidgets('is a glass switch on iOS and a platform switch without', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(
        tester,
        Center(child: AdaptiveSwitch(value: true, onChanged: (_) {})),
      );

      expect(find.byType(LiquidGlassSwitch), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsNothing);

      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(
        tester,
        Center(child: AdaptiveSwitch(value: true, onChanged: (_) {})),
      );

      expect(find.byType(LiquidGlassSwitch), findsNothing);
      expect(find.byType(CupertinoSwitch), findsOneWidget);
    });

    testWidgets('keeps the platform switch when it cannot be changed', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(
        tester,
        const Center(child: AdaptiveSwitch(value: true, onChanged: null)),
      );

      expect(find.byType(LiquidGlassSwitch), findsNothing);
      expect(find.byType(CupertinoSwitch), findsOneWidget);
    });
  });

  group('AdaptiveTopBar', () {
    testWidgets('floats a plain title instead of the nav bar', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold());

      expect(find.byType(AdaptiveTopBar), findsOneWidget);
      expect(find.byType(CupertinoSliverNavigationBar), findsNothing);
      expect(find.text('Leaderboard'), findsOneWidget);
    });

    testWidgets('keeps the collapsing nav bar without glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = false;
      await pumpGlass(tester, _scaffold());

      expect(find.byType(AdaptiveTopBar), findsNothing);
      expect(find.byType(CupertinoSliverNavigationBar), findsOneWidget);
    });

    testWidgets('leaves room above the body for the bar', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold());

      expect(
        tester.getRect(find.byKey(const Key('body'))).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byType(AdaptiveTopBar)).bottom,
        ),
      );
    });

    testWidgets('keeps the title off the glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold(onTrailingTap: () {}));

      expect(
        find.descendant(
          of: find.byType(LiquidGlassLens),
          matching: find.text('Leaderboard'),
        ),
        findsNothing,
      );
    });

    testWidgets('holds the page trailing action', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      var taps = 0;
      await pumpGlass(tester, _scaffold(onTrailingTap: () => taps++));

      expect(find.byType(LiquidGlassTabBarAction), findsOneWidget);

      await tester.tap(find.byType(AdaptiveBarAction));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('carries its own back button where the route can pop', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await _pumpPushedScaffold(tester);

      expect(_hasGlyph(tester, AdaptiveGlyph.back), isTrue);

      await tester.tap(find.byType(AdaptiveBarAction));
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTopBar), findsNothing);
    });

    testWidgets('shows no back button on a root route', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await pumpGlass(tester, _scaffold());

      expect(_hasGlyph(tester, AdaptiveGlyph.back), isFalse);
    });
  });
}

Widget _barAction() {
  return Center(
    child: AdaptiveBarAction(
      key: UniqueKey(),
      glyph: AdaptiveGlyph.settings,
      semanticLabel: 'Settings',
      onPressed: () {},
    ),
  );
}

Color? _glyphColour(WidgetTester tester, AdaptiveGlyph glyph) {
  return tester
      .widgetList<AdaptiveIcon>(find.byType(AdaptiveIcon))
      .firstWhere((icon) => icon.glyph == glyph)
      .color;
}

Set<LiquidGlassEdge> _scrollEdges(WidgetTester tester) {
  return tester
      .widgetList<LiquidGlassScrollEdge>(find.byType(LiquidGlassScrollEdge))
      .map((edge) => edge.edge)
      .toSet();
}

bool _hasGlyph(WidgetTester tester, AdaptiveGlyph glyph) {
  return tester
      .widgetList<AdaptiveIcon>(find.byType(AdaptiveIcon))
      .any((icon) => icon.glyph == glyph);
}

Future<void> _pumpPushedScaffold(WidgetTester tester) async {
  await tester.pumpWidget(
    CupertinoApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => CupertinoButton(
          onPressed: () => Navigator.of(
            context,
          ).push<void>(CupertinoPageRoute<void>(builder: (_) => _scaffold())),
          child: const Text('open'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, {bool guarded = false}) async {
  await tester.pumpWidget(
    CupertinoApp(
      home: Builder(
        builder: (context) => CupertinoButton(
          onPressed: () => showAdaptiveSheet<void>(
            context,
            confirmsDismissal: guarded,
            builder: (_) => guarded
                ? const PopScope(canPop: false, child: Text('sheet body'))
                : const Text('sheet body'),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

class _SwitchingTabBar extends StatefulWidget {
  const _SwitchingTabBar();

  @override
  State<_SwitchingTabBar> createState() => _SwitchingTabBarState();
}

class _SwitchingTabBarState extends State<_SwitchingTabBar> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBottomTabBar(
      items: const [
        AdaptiveTabBarItem(glyph: AdaptiveGlyph.leaderboard, label: 'Ranking'),
        AdaptiveTabBarItem(glyph: AdaptiveGlyph.matches, label: 'Matches'),
      ],
      selectedIndex: _selected,
      onTap: (index) => setState(() => _selected = index),
    );
  }
}

bool _isHighlighted(WidgetTester tester, AdaptiveGlyph glyph) {
  return tester
      .widgetList<AdaptiveIcon>(find.byType(AdaptiveIcon))
      .any((icon) => icon.glyph == glyph && icon.color == AppColors.seed);
}

Widget _tabBar(ValueChanged<int> onTap, {bool reservesTrailingAction = false}) {
  return AdaptiveBottomTabBar(
    items: const [
      AdaptiveTabBarItem(glyph: AdaptiveGlyph.leaderboard, label: 'Ranking'),
      AdaptiveTabBarItem(glyph: AdaptiveGlyph.matches, label: 'Matches'),
    ],
    selectedIndex: 0,
    onTap: onTap,
    reservesTrailingAction: reservesTrailingAction,
  );
}

EdgeInsets _probedPadding = EdgeInsets.zero;

Widget _paddingProbe() {
  return Builder(
    builder: (context) {
      _probedPadding = MediaQuery.paddingOf(context);
      return const SizedBox();
    },
  );
}

Future<void> _pumpInset(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(top: 65, bottom: 34),
          viewPadding: EdgeInsets.only(top: 65, bottom: 34),
        ),
        child: child,
      ),
    ),
  );
}

Widget _host({
  required Widget child,
  VoidCallback? onNewMatch,
  bool withBar = true,
}) {
  return AdaptiveBottomBarHost(
    bar: withBar ? _tabBar((_) {}, reservesTrailingAction: true) : null,
    action: onNewMatch == null
        ? null
        : AdaptiveBottomBarAction(
            glyph: AdaptiveGlyph.add,
            label: 'New match',
            onPressed: onNewMatch,
          ),
    child: child,
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

Widget _scaffold({
  bool withFloatingAction = false,
  VoidCallback? onBodyTap,
  VoidCallback? onTrailingTap,
}) {
  return _host(
    child: AdaptiveScaffold(
      title: 'Leaderboard',
      trailing: onTrailingTap == null
          ? null
          : AdaptiveBarAction(
              glyph: AdaptiveGlyph.settings,
              semanticLabel: 'Settings',
              onPressed: onTrailingTap,
            ),
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
    ),
  );
}
