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
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: child,
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
}
