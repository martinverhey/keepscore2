import 'package:flutter/widgets.dart';

class GroupedBarActionScope extends InheritedWidget {
  const GroupedBarActionScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroupedBarActionScope>() !=
      null;

  @override
  bool updateShouldNotify(GroupedBarActionScope oldWidget) => false;
}
