import 'package:flutter/widgets.dart';

class SwipeNavigator extends StatefulWidget {
  const SwipeNavigator({
    super.key,
    this.onNext,
    this.onPrevious,
    required this.child,
  });

  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Widget child;

  @override
  State<SwipeNavigator> createState() => _SwipeNavigatorState();
}

class _SwipeNavigatorState extends State<SwipeNavigator> {
  static const _minDistance = 64.0;
  static const _minVelocity = 320.0;

  double _dragged = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onHorizontalDragStart: (_) => _dragged = 0,
      onHorizontalDragUpdate: (details) => _dragged += details.delta.dx,
      onHorizontalDragEnd: _settle,
      child: widget.child,
    );
  }

  void _settle(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final isFlick = velocity.abs() >= _minVelocity;
    if (!isFlick && _dragged.abs() < _minDistance) return;

    final towardsNext = isFlick ? velocity < 0 : _dragged < 0;
    (towardsNext ? widget.onNext : widget.onPrevious)?.call();
  }
}
