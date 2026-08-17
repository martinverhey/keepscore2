import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_platform.dart';

class AdaptiveLoader extends StatelessWidget {
  const AdaptiveLoader({super.key, this.size});
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: size == null
          ? _indicator()
          : SizedBox(width: size, height: size, child: _indicator()),
    );
  }

  Widget _indicator() {
    return AppPlatform.useCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
  }
}
