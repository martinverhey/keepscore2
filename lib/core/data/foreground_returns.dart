import 'dart:async';

import 'package:flutter/widgets.dart';

Stream<void> foregroundReturns() {
  late final AppLifecycleListener listener;
  late final StreamController<void> controller;
  var wasHidden = false;

  controller = StreamController<void>(
    onListen: () {
      listener = AppLifecycleListener(
        onHide: () => wasHidden = true,
        onResume: () {
          if (!wasHidden) return;
          wasHidden = false;
          if (!controller.isClosed) controller.add(null);
        },
      );
    },
    onCancel: () => listener.dispose(),
  );

  return controller.stream;
}
