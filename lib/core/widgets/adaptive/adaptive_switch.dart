import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'adaptive_glass.dart';
import 'app_platform.dart';

class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const _height = 28.0;
  static const _width = 52.0;
  static const _visualHeight = 34.0;
  static const _webHeight = 24.0;
  static const _webWidth = 44.0;
  static const _webVisualHeight = 29.0;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    if (onChanged != null && AdaptiveGlass.isEnabled(context)) {
      return LiquidGlassSwitch(value: value, onChanged: onChanged);
    }
    return _platform(context);
  }

  Widget _platform(BuildContext context) {
    if (AppPlatform.useWideWeb(context)) {
      return _sized(
        width: _webWidth,
        height: _webHeight,
        visualHeight: _webVisualHeight,
      );
    }
    return _sized(width: _width, height: _height, visualHeight: _visualHeight);
  }

  Widget _sized({
    required double width,
    required double height,
    required double visualHeight,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: OverflowBox(
        maxHeight: visualHeight,
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
