import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/auth/domain/auth_repository.dart';
import 'package:keepscore2/features/auth/domain/auth_user.dart';
import 'package:keepscore2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _registered = AuthUser(
  id: 'user-1',
  displayName: 'Marieke',
  isGuest: false,
  email: 'marieke@example.com',
);

const _guest = AuthUser(id: 'user-2', displayName: 'Player', isGuest: true);

void main() {
  late MockAuthRepository repository;
  late StreamController<AuthUser?> users;

  setUp(() {
    repository = MockAuthRepository();
    users = StreamController<AuthUser?>.broadcast();
    when(() => repository.watchUser()).thenAnswer((_) => users.stream);
    when(() => repository.currentUser).thenReturn(null);
    when(() => repository.signOut()).thenAnswer((_) async {});
  });

  tearDown(() => users.close());

  test('starts unknown so the router can hold on the splash', () {
    expect(AuthBloc(repository).state.status, AuthStatus.unknown);
  });

  blocTest<AuthBloc, AuthSessionState>(
    'settles on unauthenticated when there is no stored session',
    build: () => AuthBloc(repository),
    expect: () => [const AuthSessionState.unauthenticated()],
  );

  blocTest<AuthBloc, AuthSessionState>(
    'seeds from a restored session without waiting for the stream',
    setUp: () => when(() => repository.currentUser).thenReturn(_registered),
    build: () => AuthBloc(repository),
    expect: () => [const AuthSessionState.authenticated(_registered)],
    verify: (bloc) {
      expect(bloc.state.canWrite, isTrue);
      expect(bloc.state.isGuest, isFalse);
    },
  );

  blocTest<AuthBloc, AuthSessionState>(
    'follows the repository stream through sign-in and sign-out',
    build: () => AuthBloc(repository),
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      users.add(_registered);
      await Future<void>.delayed(Duration.zero);
      users.add(null);
    },
    expect: () => [
      const AuthSessionState.unauthenticated(),
      const AuthSessionState.authenticated(_registered),
      const AuthSessionState.unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthSessionState>(
    'a guest is authenticated but may not write',
    build: () => AuthBloc(repository),
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      users.add(_guest);
    },
    expect: () => [
      const AuthSessionState.unauthenticated(),
      const AuthSessionState.authenticated(_guest),
    ],
    verify: (bloc) {
      expect(bloc.state.isAuthenticated, isTrue);
      expect(bloc.state.isGuest, isTrue);
      expect(bloc.state.canWrite, isFalse);
    },
  );

  blocTest<AuthBloc, AuthSessionState>(
    'sign-out delegates to the repository and waits for the stream',
    setUp: () => when(() => repository.currentUser).thenReturn(_registered),
    build: () => AuthBloc(repository),
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthSignOutRequested());
    },
    expect: () => [const AuthSessionState.authenticated(_registered)],
    verify: (_) => verify(() => repository.signOut()).called(1),
  );
}
