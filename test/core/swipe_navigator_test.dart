import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/widgets/swipe_navigator.dart';

Future<void> _pumpNavigator(
  WidgetTester tester, {
  required List<String> swipes,
  bool hasNext = true,
  bool hasPrevious = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: SwipeNavigator(
        onNext: hasNext ? () => swipes.add('next') : null,
        onPrevious: hasPrevious ? () => swipes.add('previous') : null,
        child: const SizedBox.expand(child: Text('body')),
      ),
    ),
  );
}

void main() {
  testWidgets('a flick left asks for the next, a flick right the previous', (
    tester,
  ) async {
    final swipes = <String>[];
    await _pumpNavigator(tester, swipes: swipes);

    await tester.fling(find.text('body'), const Offset(-200, 0), 800);
    await tester.pumpAndSettle();
    expect(swipes, ['next']);

    await tester.fling(find.text('body'), const Offset(200, 0), 800);
    await tester.pumpAndSettle();
    expect(swipes, ['next', 'previous']);
  });

  testWidgets('a slow drag past the threshold still counts', (tester) async {
    final swipes = <String>[];
    await _pumpNavigator(tester, swipes: swipes);

    final start = tester.getCenter(find.text('body'));
    final gesture = await tester.startGesture(start);
    for (var step = 0; step < 10; step++) {
      await gesture.moveBy(const Offset(-12, 0), timeStamp: _slow * (step + 1));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(swipes, ['next']);
  });

  testWidgets('a drag shorter than the threshold is ignored', (tester) async {
    final swipes = <String>[];
    await _pumpNavigator(tester, swipes: swipes);

    await tester.drag(find.text('body'), const Offset(-40, 0));
    await tester.pumpAndSettle();

    expect(swipes, isEmpty);
  });

  testWidgets('a swipe past the end does nothing', (tester) async {
    final swipes = <String>[];
    await _pumpNavigator(tester, swipes: swipes, hasNext: false);

    await tester.fling(find.text('body'), const Offset(-200, 0), 800);
    await tester.pumpAndSettle();

    expect(swipes, isEmpty);
  });

  testWidgets('it adds no semantics node of its own', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: SwipeNavigator(
          child: Column(children: [Text('first'), Text('second')]),
        ),
      ),
    );

    expect(find.bySemanticsLabel('first'), findsOneWidget);
    expect(find.bySemanticsLabel('second'), findsOneWidget);

    handle.dispose();
  });
}

const _slow = Duration(milliseconds: 120);
