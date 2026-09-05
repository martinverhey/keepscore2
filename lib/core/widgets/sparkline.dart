import 'dart:math';

import 'package:flutter/widgets.dart';

import '../extensions/offset_list.extension.dart';
import '../theme/app_tokens.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.width = 64,
    this.height = 28,
  });

  final List<double> values;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final offsets = _offsets(size);
    final line = offsets.smoothPath();

    _paintArea(canvas, size, offsets, line);
    _paintLine(canvas, line);
    canvas.drawCircle(offsets.last, _dotRadius, Paint()..color = color);
  }

  List<Offset> _offsets(Size size) {
    final lowest = values.reduce(min);
    final highest = values.reduce(max);
    final span = highest - lowest;
    final range = span < 1 ? 1.0 : span;
    final origin = span < 1 ? lowest - range / 2 : lowest;

    final top = _inset;
    final bottom = size.height - _inset;
    final left = _inset;
    final width = size.width - _inset * 2;
    final step = width / (values.length - 1);

    return [
      for (var i = 0; i < values.length; i++)
        Offset(
          left + step * i,
          bottom - (values[i] - origin) / range * (bottom - top),
        ),
    ];
  }

  void _paintArea(Canvas canvas, Size size, List<Offset> offsets, Path line) {
    final area = Path.from(line)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: AppOpacity.badgeFill),
            AppColors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintLine(Canvas canvas, Path line) {
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

const double _inset = 3;
const double _lineWidth = 2;
const double _dotRadius = 2.5;
