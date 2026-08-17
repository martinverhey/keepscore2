import 'package:flutter/widgets.dart';

class SuppressedBackButtonScope extends InheritedWidget {
  const SuppressedBackButtonScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SuppressedBackButtonScope>() !=
      null;

  @override
  bool updateShouldNotify(SuppressedBackButtonScope oldWidget) => false;
}
