import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_platform.dart';

class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const _height = 20.0;
  static const _width = 34.0;
  static const _visualHeight = 24.0;
  static const _visualWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: _width,
      child: OverflowBox(
        maxHeight: _visualHeight,
        maxWidth: _visualWidth,
        child: FittedBox(
          child: AppPlatform.useCupertino
              ? CupertinoSwitch(value: value, onChanged: onChanged)
              : Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
        ),
      ),
    );
  }
}
