import 'package:flutter/widgets.dart';

import '../../../profile/domain/streak_type.dart';

const fireCore = Color(0xFFFF6D00);
const _fireHot = Color(0xFFFF3D00);
const _fireGlow = Color(0xFFFFC400);
const iceCore = Color(0xFF29B6F6);
const _iceCold = Color(0xFF0288D1);
const _iceGlow = Color(0xFFE1F5FE);

Color streakCoreColor(StreakType type) =>
    type == StreakType.win ? fireCore : iceCore;

bool isRowStreak(StreakType type, int count) =>
    count >= 2 && type != StreakType.none;

class StreakRowGlow extends StatefulWidget {
  const StreakRowGlow({
    super.key,
    required this.type,
    required this.count,
    required this.fallbackColor,
    required this.borderRadius,
    required this.padding,
    required this.child,
  });

  final StreakType type;
  final int count;
  final Color fallbackColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Widget child;

  bool get isActive => isRowStreak(type, count);

  @override
  State<StreakRowGlow> createState() => _StreakRowGlowState();
}

class _StreakRowGlowState extends State<StreakRowGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StreakRowGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: widget.fallbackColor,
        ),
        child: widget.child,
      );
    }

    final isFire = widget.type == StreakType.win;
    final core = streakCoreColor(widget.type);
    final hot = isFire ? _fireHot : _iceCold;
    final glow = isFire ? _fireGlow : _iceGlow;
    final intensity = (widget.count / 6).clamp(0.5, 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final flicker = 0.5 + 0.5 * t;
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1, -1 + t * 0.6),
              end: Alignment(1, 1 - t * 0.6),
              colors: [
                hot.withValues(alpha: 0.20 * intensity),
                core.withValues(alpha: 0.12 * intensity),
                glow.withValues(alpha: 0.16 * intensity),
              ],
            ),
            border: Border.all(
              color: core.withValues(alpha: (0.35 + 0.35 * flicker) * intensity),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: core.withValues(alpha: 0.30 * flicker * intensity),
                blurRadius: 8 + 10 * flicker,
                spreadRadius: isFire ? 0.5 : 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
