import 'package:flutter/foundation.dart';

abstract final class AppPlatform {
  @visibleForTesting
  static bool? debugOverrideCupertino;

  static bool get useCupertino {
    if (debugOverrideCupertino != null) return debugOverrideCupertino!;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get useMaterial => !useCupertino;
}
