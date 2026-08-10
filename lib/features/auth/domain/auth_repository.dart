import 'auth_user.dart';

class AuthProviders {
  const AuthProviders({required this.apple, required this.google});
  final bool apple;
  final bool google;

  bool get any => apple || google;
}

abstract interface class AuthRepository {
  Stream<AuthUser?> watchUser();

  AuthUser? get currentUser;

  AuthProviders get availableProviders;

  Future<void> signInWithApple();

  Future<void> signInWithGoogle();

  Future<void> sendEmailCode(String email);

  Future<void> verifyEmailCode({required String email, required String token});

  Future<void> signInAsGuest();

  Future<void> upgradeGuestWithEmail(String email);

  Future<void> verifyUpgradeCode({required String email, required String token});

  Future<void> signOut();
}
