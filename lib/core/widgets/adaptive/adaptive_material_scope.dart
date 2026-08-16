import 'package:flutter/material.dart';

import 'app_platform.dart';

class AdaptiveMaterialScope extends StatelessWidget {
  const AdaptiveMaterialScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.useCupertino) return child;
    return Material(color: Colors.transparent, child: child);
  }
}
