import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract final class AppPlatform {
  @visibleForTesting
  static bool? debugOverrideCupertino;

  @visibleForTesting
  static bool? debugOverrideWideWeb;

  static const double wideWebBreakpoint = 720;

  static bool get useCupertino {
    if (debugOverrideCupertino != null) return debugOverrideCupertino!;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get useMaterial => !useCupertino;

  static bool useWideWeb(BuildContext context) {
    if (debugOverrideWideWeb != null) return debugOverrideWideWeb!;
    return kIsWeb && MediaQuery.sizeOf(context).width >= wideWebBreakpoint;
  }
}
