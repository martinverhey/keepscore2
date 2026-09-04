import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

const double _tailWidth = 18;
const double _tailHeight = 10;

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.color,
    required this.tailInset,
    required this.child,
  });

  final Color color;
  final double tailInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechBubblePainter(color: color, tailInset: tailInset),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          _tailHeight + AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: child,
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  _SpeechBubblePainter({required this.color, required this.tailInset});

  final Color color;
  final double tailInset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_bubblePath(size, tailInset), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tailInset != tailInset;
}

Path _bubblePath(Size size, double tailInset) {
  final tailCentre = (size.width - tailInset)
      .clamp(AppRadius.lg + _tailWidth, size.width - AppRadius.lg - _tailWidth)
      .toDouble();
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, _tailHeight, size.width, size.height),
        const Radius.circular(AppRadius.lg),
      ),
    )
    ..moveTo(tailCentre - _tailWidth / 2, _tailHeight)
    ..lineTo(tailCentre, 0)
    ..lineTo(tailCentre + _tailWidth / 2, _tailHeight)
    ..close();
}
