import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_platform.dart';

Page<T> adaptiveModalPage<T>({required Widget child, LocalKey? key}) {
  return AppPlatform.useCupertino
      ? CupertinoPage<T>(key: key, fullscreenDialog: true, child: child)
      : MaterialPage<T>(key: key, fullscreenDialog: true, child: child);
}
