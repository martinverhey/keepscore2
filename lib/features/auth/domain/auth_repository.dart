import 'auth_providers.dart';
import 'auth_user.dart';

export 'auth_providers.dart';

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

  Future<void> verifyUpgradeCode({
    required String email,
    required String token,
  });

  Future<void> signOut();
}
