import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/auth_repository.dart';
import 'sign_in_mode.enum.dart';
import 'sign_in_state.dart';

export 'sign_in_mode.enum.dart';
export 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._repository, {this.mode = SignInMode.signIn})
    : super(
        mode == SignInMode.upgrade
            ? const SignInEmailStep()
            : const SignInChooser(),
      );

  final AuthRepository _repository;
  final SignInMode mode;

  AuthProviders get providers => _repository.availableProviders;

  bool get isUpgrading => mode == SignInMode.upgrade;

  SignInEmailStep? get _email => switch (state) {
    SignInEmailStep email => email,
    _ => null,
  };

  SignInCodeStep? get _codeStep => switch (state) {
    SignInCodeStep code => code,
    _ => null,
  };

  void emailChanged(String value) {
    final email = _email;
    if (email == null) return;
    emit(email.copyWith(email: value, clearFailure: true));
  }

  void codeChanged(String value) {
    final code = _codeStep;
    if (code == null) return;
    emit(code.copyWith(code: value, clearFailure: true));
  }

  void showEmailEntry() {
    if (state is! SignInChooser) return;
    emit(const SignInEmailStep());
  }

  void back() {
    switch (state) {
      case SignInCodeStep(:final email):
        emit(SignInEmailStep(email: email));
      case SignInEmailStep():
        if (!isUpgrading) emit(const SignInChooser());
      case SignInChooser():
        return;
    }
  }

  Future<void> sendCode() async {
    final email = _email;
    if (email == null || !email.canSendCode) return;
    await _run(() async {
      await switch (mode) {
        SignInMode.signIn => _repository.sendEmailCode(email.email),
        SignInMode.upgrade => _repository.upgradeGuestWithEmail(email.email),
      };
      if (!isClosed) emit(SignInCodeStep(email: email.email, busy: true));
    });
  }

  Future<void> verifyCode() async {
    final code = _codeStep;
    if (code == null || !code.canVerify) return;
    await _run(
      () => switch (mode) {
        SignInMode.signIn => _repository.verifyEmailCode(
          email: code.email,
          token: code.code,
        ),
        SignInMode.upgrade => _repository.verifyUpgradeCode(
          email: code.email,
          token: code.code,
        ),
      },
    );
  }

  Future<void> signInWithApple() => _run(_repository.signInWithApple);

  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<void> continueAsGuest() => _run(_repository.signInAsGuest);

  Future<void> _run(Future<void> Function() action) async {
    emit(_withBusy(true));
    try {
      await action();
      if (!isClosed) emit(_withBusy(false));
    } on Failure catch (failure) {
      if (!isClosed) emit(_withFailure(failure));
    }
  }

  SignInState _withBusy(bool busy) => switch (state) {
    SignInChooser s => s.copyWith(busy: busy),
    SignInEmailStep s => s.copyWith(busy: busy),
    SignInCodeStep s => s.copyWith(busy: busy),
  };

  SignInState _withFailure(Failure failure) => switch (state) {
    SignInChooser s => s.copyWith(busy: false, failure: failure),
    SignInEmailStep s => s.copyWith(busy: false, failure: failure),
    SignInCodeStep s => s.copyWith(busy: false, failure: failure),
  };
}
