import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

sealed class SignInState extends Equatable {
  const SignInState();

  Failure? get failure => null;
}

class SignInChooser extends SignInState {
  const SignInChooser({this.busy = false, this.failure});

  final bool busy;
  @override
  final Failure? failure;

  SignInChooser copyWith({
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SignInChooser(
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [busy, failure];
}

class SignInEmailStep extends SignInState {
  const SignInEmailStep({this.email = '', this.busy = false, this.failure});

  final String email;
  final bool busy;
  @override
  final Failure? failure;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');

  bool get emailIsValid => _emailPattern.hasMatch(email.trim());

  bool get canSendCode => emailIsValid && !busy;

  SignInEmailStep copyWith({
    String? email,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SignInEmailStep(
      email: email ?? this.email,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [email, busy, failure];
}

class SignInCodeStep extends SignInState {
  const SignInCodeStep({
    required this.email,
    this.code = '',
    this.busy = false,
    this.failure,
  });

  final String email;
  final String code;
  final bool busy;
  @override
  final Failure? failure;

  bool get codeIsValid => code.trim().length == 6;

  bool get canVerify => codeIsValid && !busy;

  SignInCodeStep copyWith({
    String? code,
    bool? busy,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SignInCodeStep(
      email: email,
      code: code ?? this.code,
      busy: busy ?? this.busy,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [email, code, busy, failure];
}
