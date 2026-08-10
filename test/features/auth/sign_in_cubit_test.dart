import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/presentation/bloc/sign_in_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.availableProviders)
        .thenReturn(const AuthProviders(apple: false, google: false));
  });

  group('email validation', () {
    test('accepts a plausible address and rejects the usual mistakes', () {
      var state = const SignInState();

      for (final bad in ['', 'marieke', 'marieke@', '@example.com',
                         'marieke@example', 'a b@example.com']) {
        state = state.copyWith(email: bad);
        expect(state.emailIsValid, isFalse, reason: 'should reject "$bad"');
        expect(state.canSendCode, isFalse);
      }

      state = state.copyWith(email: 'marieke@example.com');
      expect(state.emailIsValid, isTrue);
      expect(state.canSendCode, isTrue);
    });

    test('cannot send while a request is already in flight', () {
      const state = SignInState(email: 'marieke@example.com', busy: true);
      expect(state.canSendCode, isFalse);
    });
  });

  group('sending a code', () {
    blocTest<SignInCubit, SignInState>(
      'moves to code entry on success',
      setUp: () => when(() => repository.sendEmailCode(any()))
          .thenAnswer((_) async {}),
      build: () => SignInCubit(repository),
      act: (cubit) async {
        cubit.emailChanged('marieke@example.com');
        await cubit.sendCode();
      },
      expect: () => [
        const SignInState(email: 'marieke@example.com'),
        const SignInState(email: 'marieke@example.com', busy: true),
        const SignInState(
          email: 'marieke@example.com',
          step: SignInStep.code,
          busy: true,
        ),
        const SignInState(email: 'marieke@example.com', step: SignInStep.code),
      ],
    );

    blocTest<SignInCubit, SignInState>(
      'surfaces the failure and stays on email entry',
      setUp: () => when(() => repository.sendEmailCode(any()))
          .thenThrow(const NetworkFailure()),
      build: () => SignInCubit(repository),
      act: (cubit) async {
        cubit.showEmailEntry();
        cubit.emailChanged('marieke@example.com');
        await cubit.sendCode();
      },
      verify: (cubit) {
        expect(cubit.state.step, SignInStep.email);
        expect(cubit.state.failure, isA<NetworkFailure>());
        expect(cubit.state.busy, isFalse);
      },
    );

    blocTest<SignInCubit, SignInState>(
      'does nothing when the address is not valid yet',
      build: () => SignInCubit(repository),
      act: (cubit) async {
        cubit.emailChanged('marieke@');
        await cubit.sendCode();
      },
      verify: (_) => verifyNever(() => repository.sendEmailCode(any())),
    );
  });

  group('verifying a code', () {
    blocTest<SignInCubit, SignInState>(
      'requires six digits before it will call the repository',
      build: () => SignInCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('123');
        await cubit.verifyCode();
      },
      verify: (_) => verifyNever(
        () => repository.verifyEmailCode(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ),
    );

    blocTest<SignInCubit, SignInState>(
      'passes the trimmed email and code through',
      setUp: () => when(
        () => repository.verifyEmailCode(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {}),
      build: () => SignInCubit(repository),
      act: (cubit) async {
        cubit.emailChanged('marieke@example.com');
        cubit.codeChanged('123456');
        await cubit.verifyCode();
      },
      verify: (_) => verify(
        () => repository.verifyEmailCode(
          email: 'marieke@example.com',
          token: '123456',
        ),
      ).called(1),
    );

    blocTest<SignInCubit, SignInState>(
      'a wrong code leaves the user on the code step to retry',
      setUp: () => when(
        () => repository.verifyEmailCode(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthFailure('Token has expired or is invalid')),
      build: () => SignInCubit(repository),
      act: (cubit) async {
        cubit.emailChanged('marieke@example.com');
        cubit.codeChanged('000000');
        await cubit.verifyCode();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isA<AuthFailure>());
        expect(cubit.state.busy, isFalse);
        expect(cubit.state.code, '000000');
      },
    );
  });

  group('navigation between steps', () {
    test('back from code returns to email so a typo is fixable', () async {
      when(() => repository.sendEmailCode(any())).thenAnswer((_) async {});

      final cubit = SignInCubit(repository);
      cubit.showEmailEntry();
      cubit.emailChanged('marieke@example.com');
      await cubit.sendCode();
      cubit.codeChanged('111111');
      expect(cubit.state.step, SignInStep.code);

      cubit.back();

      expect(cubit.state.step, SignInStep.email);
      expect(cubit.state.email, 'marieke@example.com');
      expect(cubit.state.code, isEmpty);
    });

    test('back from email returns to the chooser', () {
      final cubit = SignInCubit(repository)..showEmailEntry();
      cubit.back();
      expect(cubit.state.step, SignInStep.chooser);
    });
  });

  group('upgrading a guest', () {
    test('opens on email entry, because there is nothing to choose', () {
      final cubit = SignInCubit(repository, mode: SignInMode.upgrade);
      expect(cubit.state.step, SignInStep.email);
      expect(cubit.isUpgrading, isTrue);
    });

    blocTest<SignInCubit, SignInState>(
      'attaches the address to the anonymous user instead of signing in',
      setUp: () => when(() => repository.upgradeGuestWithEmail(any()))
          .thenAnswer((_) async {}),
      build: () => SignInCubit(repository, mode: SignInMode.upgrade),
      act: (cubit) async {
        cubit.emailChanged('marieke@example.com');
        await cubit.sendCode();
      },
      verify: (cubit) {
        expect(cubit.state.step, SignInStep.code);
        verify(() => repository.upgradeGuestWithEmail('marieke@example.com'))
            .called(1);
        verifyNever(() => repository.sendEmailCode(any()));
      },
    );

    blocTest<SignInCubit, SignInState>(
      'verifies against the email-change flow, not a fresh sign-in',
      setUp: () => when(
        () => repository.verifyUpgradeCode(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {}),
      build: () => SignInCubit(repository, mode: SignInMode.upgrade),
      act: (cubit) async {
        cubit.emailChanged('marieke@example.com');
        cubit.codeChanged('123456');
        await cubit.verifyCode();
      },
      verify: (_) {
        verify(
          () => repository.verifyUpgradeCode(
            email: 'marieke@example.com',
            token: '123456',
          ),
        ).called(1);
        verifyNever(
          () => repository.verifyEmailCode(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        );
      },
    );

    test('back from email stays put — the page itself is the way out', () {
      final cubit = SignInCubit(repository, mode: SignInMode.upgrade)..back();
      expect(cubit.state.step, SignInStep.email);
    });
  });

  blocTest<SignInCubit, SignInState>(
    'guest sign-in delegates to the repository',
    setUp: () =>
        when(() => repository.signInAsGuest()).thenAnswer((_) async {}),
    build: () => SignInCubit(repository),
    act: (cubit) => cubit.continueAsGuest(),
    verify: (_) => verify(() => repository.signInAsGuest()).called(1),
  );
}
