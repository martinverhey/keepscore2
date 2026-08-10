import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

enum SignInStep {
  chooser,

  email,

  code,
}

class SignInState extends Equatable {
  const SignInState({
    this.step = SignInStep.chooser,
    this.email = '',
    this.code = '',
    this.busy = false,
    this.failure,
  });

  final SignInStep step;
  final String email;
  final String code;
  final bool busy;
  final Failure? failure;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');

  bool get emailIsValid => _emailPattern.hasMatch(email.trim());

  bool get codeIsValid => code.trim().length == 6;

  bool get canSendCode => emailIsValid && !busy;

  bool get canVerify => codeIsValid && !busy;

  SignInState copyWith({
    SignInStep? step,
    String? email,
    String? code,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SignInState(
      step: step ?? this.step,
      email: email ?? this.email,
      code: code ?? this.code,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [step, email, code, busy, failure];
}
