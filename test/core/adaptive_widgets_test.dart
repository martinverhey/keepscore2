import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';

Future<void> pumpAdaptive(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    AppPlatform.useCupertino
        ? CupertinoApp(home: child)
        : MaterialApp(home: child),
  );
}

void main() {
  tearDown(() => AppPlatform.debugOverrideCupertino = null);

  group('AppPlatform', () {
    test('honours the test override in both directions', () {
      AppPlatform.debugOverrideCupertino = true;
      expect(AppPlatform.useCupertino, isTrue);
      expect(AppPlatform.useMaterial, isFalse);

      AppPlatform.debugOverrideCupertino = false;
      expect(AppPlatform.useCupertino, isFalse);
      expect(AppPlatform.useMaterial, isTrue);
    });
  });

  group('AdaptiveScaffold', () {
    testWidgets('renders a Material Scaffold when not on Cupertino', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      await pumpAdaptive(
        tester,
        const AdaptiveScaffold(title: 'Leaderboard', body: Text('body')),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CupertinoPageScaffold), findsNothing);
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.text('Leaderboard'), findsWidgets);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('renders a CupertinoPageScaffold on iOS', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      await pumpAdaptive(
        tester,
        const AdaptiveScaffold(title: 'Leaderboard', body: Text('body')),
      );

      expect(find.byType(CupertinoPageScaffold), findsOneWidget);
      expect(find.byType(CupertinoSliverNavigationBar), findsOneWidget);
      expect(find.text('Leaderboard'), findsWidgets);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('scrolls a long body under a collapsing title', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      await pumpAdaptive(
        tester,
        const AdaptiveScaffold(
          title: 'Leaderboard',
          body: SizedBox(height: 4000, child: Text('body')),
        ),
      );

      final expanded = tester.getSize(find.byType(AppBar)).height;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(AppBar)).height, lessThan(expanded));
      expect(find.text('Leaderboard'), findsWidgets);
    });
  });

  group('AdaptiveButton', () {
    testWidgets('swallows taps and hides the label while busy', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      var taps = 0;
      await pumpAdaptive(
        tester,
        AdaptiveButton(
          label: 'Save match',
          busy: true,
          onPressed: () => taps++,
        ),
      );

      expect(find.text('Save match'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('fires when idle', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      var taps = 0;
      await pumpAdaptive(
        tester,
        AdaptiveButton(label: 'Save match', onPressed: () => taps++),
      );

      await tester.tap(find.text('Save match'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
