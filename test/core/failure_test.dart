import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('guard', () {
    test('maps AuthRetryableFetchException to NetworkFailure', () async {
      await expectLater(
        guard<void>(
          () async => throw AuthRetryableFetchException(
            message: 'HandshakeException: Connection terminated during '
                'handshake',
          ),
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('maps other AuthException subtypes to AuthFailure', () async {
      await expectLater(
        guard<void>(
          () async => throw AuthApiException('invalid refresh token'),
        ),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
