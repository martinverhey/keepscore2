import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/rating_point.dart';

class RatingTrendChart extends StatelessWidget {
  const RatingTrendChart({super.key, required this.points});
  final List<RatingPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: CustomPaint(
        painter: _RatingTrendPainter(
          points: points,
          color: AdaptiveColors.accent(context),
        ),
      ),
    );
  }
}

class _RatingTrendPainter extends CustomPainter {
  _RatingTrendPainter({required this.points, required this.color});

  final List<RatingPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final ratings = [for (final point in points) point.ratingAfter];
    final minRating = ratings.reduce(min);
    final maxRating = ratings.reduce(max);
    final range = (maxRating - minRating).abs() < 1
        ? 1.0
        : maxRating - minRating;
    final step = size.width / (points.length - 1);

    Offset offsetAt(int index) {
      final normalized = (ratings[index] - minRating) / range;
      return Offset(step * index, size.height - normalized * size.height);
    }

    final path = Path()..moveTo(offsetAt(0).dx, offsetAt(0).dy);
    for (var i = 1; i < points.length; i++) {
      final point = offsetAt(i);
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      canvas.drawCircle(offsetAt(i), isLast ? 4 : 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RatingTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
