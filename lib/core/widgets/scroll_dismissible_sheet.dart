import 'package:flutter/widgets.dart';

import 'scroll_dismiss_scope.dart';

class ScrollDismissibleSheet extends StatefulWidget {
  const ScrollDismissibleSheet({super.key, required this.child});

  final Widget child;

  @override
  State<ScrollDismissibleSheet> createState() => _ScrollDismissibleSheetState();
}

class _ScrollDismissibleSheetState extends State<ScrollDismissibleSheet> {
  static const _dismissThreshold = 120.0;
  static const _settleDuration = Duration(milliseconds: 220);

  double _dragExtent = 0;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: AnimatedSlide(
        duration: _dragging ? Duration.zero : _settleDuration,
        curve: Curves.easeOut,
        offset: Offset(0, _dragExtent / screenHeight),
        child: AnimatedOpacity(
          duration: _dragging ? Duration.zero : _settleDuration,
          opacity: 1 - (_dragExtent / (screenHeight * 0.5)).clamp(0.0, 1.0),
          child: ScrollDismissScope(
            isDragging: () => _dragExtent > 0,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      _updateDragExtent(_dragExtent - notification.overscroll);
    } else if (notification is ScrollEndNotification && _dragExtent > 0) {
      _dragging = false;
      if (_dragExtent > _dismissThreshold) {
        Navigator.of(context).maybePop();
      } else {
        setState(() => _dragExtent = 0);
      }
    }
    return false;
  }

  void _updateDragExtent(double extent) {
    final clamped = extent.clamp(0.0, double.infinity);
    final dragging = clamped > 0;
    if (clamped == _dragExtent && dragging == _dragging) return;
    setState(() {
      _dragging = dragging;
      _dragExtent = clamped;
    });
  }
}
