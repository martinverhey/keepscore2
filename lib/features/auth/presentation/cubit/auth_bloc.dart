import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/auth_repository.dart';
import '../../domain/auth_user.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticated,
}

class AuthSessionState extends Equatable {
  const AuthSessionState._({required this.status, this.user});
  const AuthSessionState.unknown() : this._(status: AuthStatus.unknown);

  const AuthSessionState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  const AuthSessionState.authenticated(AuthUser user)
      : this._(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final AuthUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get canWrite => user?.isRegistered ?? false;

  bool get isGuest => user?.isGuest ?? false;

  @override
  List<Object?> get props => [status, user];
}

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final AuthUser? user;

  @override
  List<Object?> get props => [user];
}

class AuthBloc extends Bloc<AuthEvent, AuthSessionState> {
  AuthBloc(this._repository) : super(const AuthSessionState.unknown()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onUserChanged);

    add(const AuthSubscriptionRequested());
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _subscription;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthSessionState> emit,
  ) async {
    final existing = _repository.currentUser;
    emit(existing == null
        ? const AuthSessionState.unauthenticated()
        : AuthSessionState.authenticated(existing));

    await _subscription?.cancel();
    _subscription = _repository.watchUser().listen(
          (user) => add(_AuthUserChanged(user)),
        );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthSessionState> emit) {
    emit(event.user == null
        ? const AuthSessionState.unauthenticated()
        : AuthSessionState.authenticated(event.user!));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthSessionState> emit,
  ) async {
    await _repository.signOut();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
