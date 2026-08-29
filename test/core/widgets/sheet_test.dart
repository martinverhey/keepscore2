import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
