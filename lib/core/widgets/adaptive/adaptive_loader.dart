import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_platform.dart';

class AdaptiveLoader extends StatelessWidget {
  const AdaptiveLoader({super.key, this.size});
  final double? size;

  @override
  Widget build(BuildContext context) {
    final child = AppPlatform.useCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
    return Center(
      child: size == null
          ? child
          : SizedBox(width: size, height: size, child: child),
    );
  }
}
