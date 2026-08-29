import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_platform.dart';

Page<T> adaptivePage<T>(
  BuildContext context, {
  required Widget child,
  LocalKey? key,
}) {
  if (!AppPlatform.useWideWeb(context)) {
    return AppPlatform.useCupertino
        ? CupertinoPage<T>(key: key, child: child)
        : MaterialPage<T>(key: key, child: child);
  }
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
