import 'package:flutter/widgets.dart';

class TriangleIcon extends StatelessWidget {
  const TriangleIcon({
    super.key,
    required this.pointsUp,
    required this.color,
    required this.size,
  });

  final bool pointsUp;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TrianglePainter(pointsUp: pointsUp, color: color),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.pointsUp, required this.color});

  final bool pointsUp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pointsUp
        ? (Path()
            ..moveTo(size.width / 2, 0)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close())
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width / 2, size.height)
            ..close());
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.pointsUp != pointsUp || oldDelegate.color != color;
}
