import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/core/widgets/sheet.dart';

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAdaptiveSheet<void>(
              context,
              builder: (_) =>
                  const Sheet(title: 'Sheet', content: SizedBox(height: 2000)),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _openGuardedSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAdaptiveSheet<void>(
              context,
              confirmsDismissal: true,
              builder: (_) => const PopScope(
                canPop: false,
                child: Sheet(title: 'Sheet', content: SizedBox(height: 2000)),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _openMeasuredSheet(WidgetTester tester, {String? title}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAdaptiveSheet<void>(
              context,
              builder: (_) => Sheet(
                title: title,
                content: const Column(
                  children: [Text('content top'), SizedBox(height: 2000)],
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _openSheetAboveABar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Column(
        children: [
          Expanded(
            child: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => showAdaptiveSheet<void>(
                      context,
                      builder: (_) => const Sheet(
                        title: 'Sheet',
                        content: SizedBox(height: 200),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 80,
            child: ColoredBox(color: Color(0xFF000000)),
          ),
        ],
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    AppPlatform.debugOverrideCupertino = null;
    AppPlatform.debugOverrideWideWeb = null;
  });

  group('Sheet drag-to-dismiss', () {
    testWidgets('dragging the content down past the threshold closes it', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheet(tester);

      expect(find.byType(Sheet), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsNothing);
    });

    testWidgets('dragging the content down under the threshold snaps back', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheet(tester);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 40),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsOneWidget);
    });

    testWidgets('dragging the title down past the threshold closes it', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheet(tester);

      await tester.drag(find.text('Sheet'), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsNothing);
    });

    testWidgets('dragging the title down under the threshold snaps back', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheet(tester);

      await tester.drag(find.text('Sheet'), const Offset(0, 40));
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsOneWidget);
    });

    testWidgets('closes from the title in the cupertino presentation too', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheet(tester);

      await tester.drag(find.text('Sheet'), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsNothing);
    });

    testWidgets('is not enabled for the wide-web dialog presentation', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = true;
      await _openSheet(tester);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsOneWidget);
    });

    testWidgets('also closes the cupertino modal popup presentation', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheet(tester);

      expect(find.byType(Sheet), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsNothing);
    });

    testWidgets('a refused dismissal springs the sheet back to rest', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openGuardedSheet(tester);

      await tester.drag(find.text('Sheet'), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byType(Sheet), findsOneWidget);
      expect(
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
        Offset.zero,
      );
    });

    testWidgets(
      'reversing direction mid-drag springs back without scrolling the content',
      (tester) async {
        AppPlatform.debugOverrideCupertino = false;
        AppPlatform.debugOverrideWideWeb = false;
        await _openSheet(tester);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(SingleChildScrollView)),
        );
        for (var step = 0; step < 20; step++) {
          await gesture.moveBy(const Offset(0, 10));
          await tester.pump();
        }
        for (var step = 0; step < 10; step++) {
          await gesture.moveBy(const Offset(0, -10));
          await tester.pump();
        }

        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        expect(position.pixels, 0);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(Sheet), findsOneWidget);
      },
    );
  });

  group('Sheet header gap', () {
    testWidgets('sits under the header at rest and scrolls away with the '
        'content', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openMeasuredSheet(tester, title: 'Sheet');

      final scrollView = find.byType(SingleChildScrollView);
      final content = find.text('content top');

      expect(
        tester.getRect(content).top - tester.getRect(scrollView).top,
        AppSpacing.lg,
      );

      await tester.drag(scrollView, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(content).top,
        lessThan(tester.getRect(scrollView).top),
      );
    });

    testWidgets('is absent from a sheet with no header', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openMeasuredSheet(tester);

      expect(
        tester.getRect(find.text('content top')).top,
        tester.getRect(find.byType(SingleChildScrollView)).top,
      );
    });
  });

  group('Sheet host navigator', () {
    testWidgets('covers a bottom bar that sits outside the nested navigator', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheetAboveABar(tester);

      expect(
        tester.getRect(find.byType(Sheet)).bottom,
        tester.getSize(find.byType(MaterialApp)).height,
      );
    });
  });
}
