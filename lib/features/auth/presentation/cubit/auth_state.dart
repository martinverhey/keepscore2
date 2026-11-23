import 'package:equatable/equatable.dart';

import '../../domain/auth_user.model.dart';

sealed class AuthSessionState extends Equatable {
  const AuthSessionState();

  AuthUser? get user => null;

  bool get isAuthenticated => false;

  bool get canWrite => user?.isRegistered ?? false;

  bool get isGuest => user?.isGuest ?? false;

  @override
  List<Object?> get props => const [];
}

final class AuthUnknown extends AuthSessionState {
  const AuthUnknown();
}

final class AuthUnauthenticated extends AuthSessionState {
  const AuthUnauthenticated();
}

final class AuthAuthenticated extends AuthSessionState {
  const AuthAuthenticated(this.user);

  @override
  final AuthUser user;

  @override
  bool get isAuthenticated => true;

  @override
  List<Object?> get props => [user];
}
