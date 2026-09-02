import 'package:package_info_plus/package_info_plus.dart';

abstract final class AppVersion {
  static String? _label;

  static String? debugOverrideLabel;

  static String? get label => debugOverrideLabel ?? _label;

  static Future<void> load() async {
    final info = await PackageInfo.fromPlatform();
    _label = info.buildNumber.isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';
  }
}
