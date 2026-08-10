import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static const _envAsset = 'assets/.env';

  static final _forbidden = RegExp(
    r'(PASSWORD|SECRET|SERVICE_ROLE|PRIVATE_KEY|ACCESS_TOKEN)',
    caseSensitive: false,
  );

  static Future<void> load() async {
    await dotenv.load(fileName: _envAsset);
    _assertNoSecrets();
  }

  static void _assertNoSecrets() {
    assert(() {
      final leaked = dotenv.env.keys.where(_forbidden.hasMatch).toList();
      if (leaked.isNotEmpty) {
        throw StateError(
          'Refusing to run: $_envAsset is shipped inside the app bundle and '
          'contains ${leaked.join(', ')}. Move those to the project-root .env, '
          'which is never bundled.',
        );
      }
      return true;
    }());
  }

  static String get supabaseUrl => _require('SUPABASE_URL');

  static String get supabasePublishableKey => _require('SUPABASE_PUBLISHABLE_KEY');

  static bool get appleSignInEnabled => _flag('AUTH_APPLE_ENABLED');

  static bool get googleSignInEnabled => _flag('AUTH_GOOGLE_ENABLED');

  static String? get googleServerClientId => _optional('GOOGLE_SERVER_CLIENT_ID');

  static String? get googleIosClientId => _optional('GOOGLE_IOS_CLIENT_ID');

  static String? get appleServiceId => _optional('APPLE_SERVICE_ID');

  static String? get appleRedirectUri => _optional('APPLE_REDIRECT_URI');

  static String? get oauthRedirectUrl => _optional('OAUTH_REDIRECT_URL');

  static String? _optional(String key) {
    final value = dotenv.env[key];
    return (value == null || value.isEmpty) ? null : value;
  }

  static bool _flag(String key) => _optional(key)?.toLowerCase() == 'true';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing $key in $_envAsset.',
      );
    }
    return value;
  }
}
