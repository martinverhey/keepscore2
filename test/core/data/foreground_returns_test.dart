import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/data/foreground_returns.dart';

const _toBackground = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];

const _toForeground = [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

void main() {
  testWidgets('ticks once when the app returns from the background', (
    tester,
  ) async {
    var ticks = 0;
    final subscription = foregroundReturns().listen((_) => ticks++);
    addTearDown(subscription.cancel);

    await _walk(tester, _toBackground);
    expect(ticks, 0);

    await _walk(tester, _toForeground);
    expect(ticks, 1);
  });

  testWidgets('ignores a resume that never left the foreground', (
    tester,
  ) async {
    var ticks = 0;
    final subscription = foregroundReturns().listen((_) => ticks++);
    addTearDown(subscription.cancel);

    await _walk(tester, const [
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);

    expect(ticks, 0);
  });

  testWidgets('stops listening once cancelled', (tester) async {
    var ticks = 0;
    final subscription = foregroundReturns().listen((_) => ticks++);
    subscription.cancel();

    await _walk(tester, _toBackground);
    await _walk(tester, _toForeground);

    expect(ticks, 0);
  });
}

Future<void> _walk(WidgetTester tester, List<AppLifecycleState> states) async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.idle();
  }
}
