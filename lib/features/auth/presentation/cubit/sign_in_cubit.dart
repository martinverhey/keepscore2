import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/auth_repository.dart';
import 'sign_in_mode.dart';
import 'sign_in_state.dart';

export 'sign_in_mode.dart';
export 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._repository, {this.mode = SignInMode.signIn})
    : super(
        SignInState(
          step: mode == SignInMode.upgrade
              ? SignInStep.email
              : SignInStep.chooser,
        ),
      );

  final AuthRepository _repository;
  final SignInMode mode;

  AuthProviders get providers => _repository.availableProviders;

  bool get isUpgrading => mode == SignInMode.upgrade;

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, clearFailure: true));

  void codeChanged(String value) =>
      emit(state.copyWith(code: value, clearFailure: true));

  void showEmailEntry() =>
      emit(state.copyWith(step: SignInStep.email, clearFailure: true));

  void back() {
    final previous = switch (state.step) {
      SignInStep.code => SignInStep.email,
      _ => isUpgrading ? SignInStep.email : SignInStep.chooser,
    };
    emit(state.copyWith(step: previous, code: '', clearFailure: true));
  }

  Future<void> sendCode() async {
    if (!state.canSendCode) return;
    await _run(() async {
      await switch (mode) {
        SignInMode.signIn => _repository.sendEmailCode(state.email),
        SignInMode.upgrade => _repository.upgradeGuestWithEmail(state.email),
      };
      emit(state.copyWith(step: SignInStep.code, code: ''));
    });
  }

  Future<void> verifyCode() async {
    if (!state.canVerify) return;
    await _run(
      () => switch (mode) {
        SignInMode.signIn => _repository.verifyEmailCode(
          email: state.email,
          token: state.code,
        ),
        SignInMode.upgrade => _repository.verifyUpgradeCode(
          email: state.email,
          token: state.code,
        ),
      },
    );
  }

  Future<void> signInWithApple() => _run(_repository.signInWithApple);

  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<void> continueAsGuest() => _run(_repository.signInAsGuest);

  Future<void> _run(Future<void> Function() action) async {
    emit(state.copyWith(busy: true, clearFailure: true));
    try {
      await action();
      if (!isClosed) emit(state.copyWith(busy: false));
    } on Failure catch (failure) {
      if (!isClosed) emit(state.copyWith(busy: false, failure: failure));
    }
  }
}
