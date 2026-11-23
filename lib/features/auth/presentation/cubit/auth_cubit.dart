import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/auth_repository.dart';
import '../../domain/auth_user.model.dart';
import 'auth_state.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthSessionState> {
  AuthCubit(this._repository) : super(const AuthUnknown()) {
    scheduleMicrotask(_restoreSession);
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _subscription;

  Future<void> signOut() => _repository.signOut();

  void _restoreSession() {
    if (isClosed) return;
    _emitFor(_repository.currentUser);
    _subscription = _repository.watchUser().listen(_emitFor);
  }

  void _emitFor(AuthUser? user) {
    emit(user == null ? const AuthUnauthenticated() : AuthAuthenticated(user));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
