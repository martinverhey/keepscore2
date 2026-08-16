import 'package:flutter/material.dart';

import 'app_platform.dart';

class AdaptiveTappable extends StatelessWidget {
  const AdaptiveTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.useCupertino) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }
    return Material(
      type: MaterialType.transparency,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
    );
  }
}
