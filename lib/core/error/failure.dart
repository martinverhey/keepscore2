import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network unavailable']);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Not allowed']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unexpected error']);
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Failure {
    rethrow;
  } on AuthException catch (e) {
    throw AuthFailure(e.message);
  } on PostgrestException catch (e) {
    throw _fromPostgrest(e);
  } on SocketException catch (e) {
    throw NetworkFailure(e.message);
  } on TimeoutException {
    throw const NetworkFailure('Request timed out');
  } catch (e) {
    throw UnknownFailure(e.toString());
  }
}

Failure _fromPostgrest(PostgrestException e) {
  return switch (e.code) {
    '42501' || 'PGRST301' => PermissionFailure(e.message),
    'P0001' || '23514' || '23505' => ValidationFailure(e.message),
    _ => UnknownFailure(e.message),
  };
}
