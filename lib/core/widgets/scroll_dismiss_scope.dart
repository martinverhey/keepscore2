import 'package:flutter/widgets.dart';

class ScrollDismissScope extends InheritedWidget {
  const ScrollDismissScope({
    super.key,
    required this.isDragging,
    required super.child,
  });

  final bool Function() isDragging;

  static ScrollPhysics physicsOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ScrollDismissScope>();
    if (scope == null) {
      return const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return _DismissDragScrollPhysics(isDragging: scope.isDragging);
  }

  @override
  bool updateShouldNotify(ScrollDismissScope oldWidget) => false;
}

class _DismissDragScrollPhysics extends ClampingScrollPhysics {
  const _DismissDragScrollPhysics({required this.isDragging, super.parent});

  final bool Function() isDragging;

  @override
  _DismissDragScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _DismissDragScrollPhysics(
      isDragging: isDragging,
      parent: buildParent(ancestor),
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (isDragging() && position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }
}
