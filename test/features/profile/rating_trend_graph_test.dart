import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/profile/domain/rating_point.model.dart';
import 'package:keepscore2/features/profile/presentation/widgets/rating_trend_graph.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

List<RatingPoint> _climbing([int count = 5]) => [
  for (var i = 0; i < count; i++)
    RatingPoint(
      playedAt: DateTime(2026, 8, 20 + i),
      ratingAfter: 1000 + i * 25,
      ratingDelta: 25,
    ),
];

Future<Rect> _pump(WidgetTester tester, List<RatingPoint> points) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, _) => Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 320, child: RatingTrendGraph(points: points)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getRect(find.byType(RatingTrendGraph));
}

void main() {
  testWidgets('scrubbing names the oldest match on the left and the newest '
      'on the right', (tester) async {
    final chart = await _pump(tester, _climbing());

    await tester.tapAt(Offset(chart.left + 2, chart.center.dy));
    await tester.pump();
    expect(find.text('1000'), findsOneWidget);

    await tester.tapAt(Offset(chart.right - 2, chart.center.dy));
    await tester.pump();
    expect(find.text('1100'), findsOneWidget);
  });

  testWidgets('dragging moves the readout with the finger, and it survives '
      'the release', (tester) async {
    final chart = await _pump(tester, _climbing());
    final gesture = await tester.startGesture(
      Offset(chart.left + 2, chart.center.dy),
    );
    await gesture.moveTo(Offset(chart.center.dx - 16, chart.center.dy));
    await tester.pump();

    expect(find.text('1000'), findsNothing);
    expect(find.text('1050'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.text('1050'), findsOneWidget);
  });

  testWidgets('tapping the same match again puts the readout away', (
    tester,
  ) async {
    final chart = await _pump(tester, _climbing());
    final spot = Offset(chart.left + 2, chart.center.dy);

    await tester.tapAt(spot);
    await tester.pump();
    expect(find.text('1000'), findsOneWidget);

    await tester.tapAt(spot);
    await tester.pump();
    expect(find.text('1000'), findsNothing);
  });

  testWidgets('the newest match keeps its whole marker inside the graph', (
    tester,
  ) async {
    const markerCentre = 310.0;
    const haloRadius = 8.0;
    final chart = await _pump(tester, _climbing(2));

    expect(
      find.byType(RatingTrendGraph),
      paints
        ..circle(radius: 2.5)
        ..circle(x: markerCentre, y: 24, radius: haloRadius),
    );
    expect(markerCentre + haloRadius, lessThanOrEqualTo(chart.width));
  });

  testWidgets('a single point is not enough to draw a trend', (tester) async {
    await _pump(tester, [_climbing().first]);

    expect(
      find.descendant(
        of: find.byType(RatingTrendGraph),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
