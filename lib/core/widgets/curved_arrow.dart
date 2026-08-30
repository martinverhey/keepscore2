import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'curved_arrow_direction.enum.dart';

const double _headLength = 11;
const double _headSpread = 0.55;

class CurvedArrow extends StatelessWidget {
  const CurvedArrow({
    super.key,
    required this.direction,
    required this.color,
    required this.size,
    this.strokeWidth = 2,
  });

  final CurvedArrowDirection direction;
  final Color color;
  final Size size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _CurvedArrowPainter(
        direction: direction,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  _CurvedArrowPainter({
    required this.direction,
    required this.color,
    required this.strokeWidth,
  });

  final CurvedArrowDirection direction;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _tailPath(size, direction);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    canvas.drawPath(_headPath(path), paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) =>
      oldDelegate.direction != direction ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

Path _tailPath(Size size, CurvedArrowDirection direction) {
  final width = size.width;
  final height = size.height;
  return switch (direction) {
    CurvedArrowDirection.down =>
      Path()
        ..moveTo(width * 0.06, 0)
        ..cubicTo(
          0,
          height * 0.46,
          width * 0.88,
          height * 0.42,
          width * 0.65,
          height,
        ),
    CurvedArrowDirection.left =>
      Path()
        ..moveTo(width, height * 0.4)
        ..cubicTo(
          width * 0.25,
          0,
          width * 0.4,
          height * -0.95,
          0,
          height * -0.85,
        ),
  };
}

Path _headPath(Path tail) {
  final metric = tail.computeMetrics().first;
  final tangent = metric.getTangentForOffset(metric.length)!;
  final tip = tangent.position;
  final back = math.atan2(tangent.vector.dy, tangent.vector.dx) + math.pi;
  return Path()
    ..moveTo(
      tip.dx + _headLength * math.cos(back - _headSpread),
      tip.dy + _headLength * math.sin(back - _headSpread),
    )
    ..lineTo(tip.dx, tip.dy)
    ..lineTo(
      tip.dx + _headLength * math.cos(back + _headSpread),
      tip.dy + _headLength * math.sin(back + _headSpread),
    );
}
