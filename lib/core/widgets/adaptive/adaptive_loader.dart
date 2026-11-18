import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'app_platform.dart';

class AdaptiveLoader extends StatelessWidget {
  const AdaptiveLoader({super.key, this.size, this.color});
  final double? size;
  final Color? color;

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
        ? CupertinoActivityIndicator(color: color)
        : CircularProgressIndicator(color: color);
  }
}
