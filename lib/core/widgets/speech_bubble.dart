import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'speech_bubble_tail.enum.dart';

export 'speech_bubble_tail.enum.dart';

const double _tailWidth = 18;
const double _tailHeight = 10;

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.color,
    required this.tailInset,
    required this.child,
    required this.tail,
  });

  final Color color;
  final double tailInset;
  final Widget child;
  final SpeechBubbleTail tail;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechBubblePainter(
        color: color,
        tailInset: tailInset,
        tail: tail,
      ),
      child: Padding(padding: _padding(), child: child),
    );
  }

  EdgeInsets _padding() {
    return EdgeInsets.fromLTRB(
      tail == SpeechBubbleTail.left
          ? _tailHeight + AppSpacing.md
          : AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      tail == SpeechBubbleTail.bottom
          ? _tailHeight + AppSpacing.md
          : AppSpacing.md,
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  _SpeechBubblePainter({
    required this.color,
    required this.tailInset,
    required this.tail,
  });

  final Color color;
  final double tailInset;
  final SpeechBubbleTail tail;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_bubblePath(size, tailInset, tail), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.tailInset != tailInset ||
      oldDelegate.tail != tail;
}

Path _bubblePath(Size size, double tailInset, SpeechBubbleTail tail) {
  return switch (tail) {
    SpeechBubbleTail.left => _sideTailPath(size, tailInset),
    SpeechBubbleTail.bottom => _bottomTailPath(size, tailInset),
  };
}

Path _bottomTailPath(Size size, double tailInset) {
  final tailCentre = (size.width - tailInset)
      .clamp(AppRadius.lg + _tailWidth, size.width - AppRadius.lg - _tailWidth)
      .toDouble();
  final baseline = size.height - _tailHeight;
  final tip = size.height;
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, 0, size.width, size.height - _tailHeight),
        const Radius.circular(AppRadius.lg),
      ),
    )
    ..moveTo(tailCentre - _tailWidth / 2, baseline)
    ..lineTo(tailCentre, tip)
    ..lineTo(tailCentre + _tailWidth / 2, baseline)
    ..close();
}

Path _sideTailPath(Size size, double tailInset) {
  final tailCentre = tailInset
      .clamp(AppRadius.lg + _tailWidth, size.height - AppRadius.lg - _tailWidth)
      .toDouble();
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(_tailHeight, 0, size.width, size.height),
        const Radius.circular(AppRadius.lg),
      ),
    )
    ..moveTo(_tailHeight, tailCentre - _tailWidth / 2)
    ..lineTo(0, tailCentre)
    ..lineTo(_tailHeight, tailCentre + _tailWidth / 2)
    ..close();
}
