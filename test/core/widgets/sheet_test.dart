import 'dart:ui' show SemanticsAction;

import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/theme/app_tokens.dart';
import 'package:keepscore2/core/widgets/adaptive/adaptive.dart';
import 'package:keepscore2/core/widgets/sheet.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoApp, CupertinoButton;
import 'package:material_ui/material_ui.dart';

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

Future<void> _openTallSheet(
  WidgetTester tester, {
  Widget? primaryButton,
}) async {
  tester.view.padding = const FakeViewPadding(bottom: _bottomSafeArea * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAdaptiveSheet<void>(
              context,
              builder: (_) => Sheet(
                title: 'Sheet',
                primaryButton: primaryButton,
                content: const Column(
                  children: [SizedBox(height: 2000), Text('content bottom')],
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

const _bottomSafeArea = 34.0;

void main() {
  tearDown(() {
    AppPlatform.debugOverrideCupertino = null;
    AppPlatform.debugOverrideWideWeb = null;
    AppPlatform.debugOverrideLiquidGlass = null;
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
        AppSpacing.lg - AppSpacing.md,
      );
      expect(
        tester.getRect(scrollView).top -
            tester.getRect(find.text('Sheet')).bottom,
        AppSpacing.md,
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

  group('Sheet bottom inset', () {
    testWidgets('lets the content scroll to the sheet edge and rest clear of '
        'the safe area', (tester) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openTallSheet(tester);
      final screenBottom = tester.view.physicalSize.height / 3;

      expect(
        tester.getRect(find.byType(SingleChildScrollView)).bottom,
        screenBottom,
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('content bottom')).bottom,
        screenBottom - AppSpacing.lg - _bottomSafeArea,
      );
    });

    testWidgets('stays outside the scroll view above a pinned button', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = false;
      AppPlatform.debugOverrideWideWeb = false;
      await _openTallSheet(
        tester,
        primaryButton: const SizedBox(height: 48, key: Key('button')),
      );
      final screenBottom = tester.view.physicalSize.height / 3;

      expect(
        tester.getRect(find.byKey(const Key('button'))).bottom,
        screenBottom - AppSpacing.lg - _bottomSafeArea,
      );
      expect(
        tester.getRect(find.byType(SingleChildScrollView)).bottom,
        tester.getRect(find.byKey(const Key('button'))).top - AppSpacing.lg,
      );
    });
  });

  group('Sheet header on glass', () {
    testWidgets('sits the same gap above the content at rest', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await _openMeasuredSheet(tester, title: 'Sheet');

      expect(
        tester.getRect(find.text('content top')).top -
            tester.getRect(find.text('Sheet')).bottom,
        AppSpacing.lg,
      );
    });

    testWidgets('lets the content scroll under it behind a scroll edge', (
      tester,
    ) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await _openMeasuredSheet(tester, title: 'Sheet');
      final title = tester.getRect(find.text('Sheet'));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text('Sheet')), title);
      expect(
        tester.getRect(find.text('content top')).top,
        lessThan(title.bottom),
      );
      expect(find.byType(LiquidGlassScrollEdge), findsOneWidget);
    });

    testWidgets('keeps a custom header pinned on glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = true;
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showAdaptiveSheet<void>(
                context,
                builder: (_) => const Sheet(
                  header: Text('tabs'),
                  content: SizedBox(height: 2000),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlassScrollEdge), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('keeps the pinned header off glass', (tester) async {
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideLiquidGlass = false;
      await _openMeasuredSheet(tester, title: 'Sheet');

      expect(find.byType(LiquidGlassScrollEdge), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('Sheet barrier', () {
    testWidgets('a screen reader can dismiss the cupertino presentation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      AppPlatform.debugOverrideCupertino = true;
      AppPlatform.debugOverrideWideWeb = false;
      await _openSheet(tester);

      final barrier = tester.getSemantics(find.bySemanticsLabel('Dismiss'));
      expect(barrier.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(
        barrier.getSemanticsData().hasAction(SemanticsAction.dismiss),
        isTrue,
      );

      semantics.dispose();
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
