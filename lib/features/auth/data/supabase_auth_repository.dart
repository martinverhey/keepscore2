import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/config/env.dart';
import '../../../core/error/failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Future<void>? _googleInit;

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _fromUser(user);
  }

  @override
  AuthProviders get availableProviders => AuthProviders(
        apple: Env.appleSignInEnabled,
        google: Env.googleSignInEnabled,
      );

  @override
  Stream<AuthUser?> watchUser() {
    return _auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return _withProfile(_fromUser(user));
    });
  }

  Future<AuthUser> _withProfile(AuthUser user) async {
    try {
      final row = await _client
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return user;
      return user.copyWith(
        displayName: (row['display_name'] as String?)?.trim(),
        avatarUrl: row['avatar_url'] as String?,
      );
    } catch (_) {
      return user;
    }
  }

  AuthUser _fromUser(User user) {
    final meta = user.userMetadata ?? const {};
    final fromMeta = (meta['full_name'] ?? meta['name'] ?? meta['display_name'])
        as String?;
    final fromEmail = user.email?.split('@').first;
    return AuthUser(
      id: user.id,
      displayName: (fromMeta?.trim().isNotEmpty ?? false)
          ? fromMeta!.trim()
          : (fromEmail?.isNotEmpty ?? false)
              ? fromEmail!
              : 'Player',
      isGuest: user.isAnonymous,
      email: user.email,
      avatarUrl: meta['avatar_url'] as String?,
    );
  }

  @override
  Future<void> sendEmailCode(String email) => guard(() async {
        await _auth.signInWithOtp(
          email: email.trim(),
          shouldCreateUser: true,
        );
      });

  @override
  Future<void> verifyEmailCode({
    required String email,
    required String token,
  }) =>
      guard(() async {
        await _auth.verifyOTP(
          type: OtpType.email,
          email: email.trim(),
          token: token.trim(),
        );
      });

  @override
  Future<void> signInAsGuest() => guard(() async {
        await _auth.signInAnonymously();
      });

  @override
  Future<void> upgradeGuestWithEmail(String email) => guard(() async {
        await _auth.updateUser(UserAttributes(email: email.trim()));
      });

  @override
  Future<void> verifyUpgradeCode({
    required String email,
    required String token,
  }) =>
      guard(() async {
        await _auth.verifyOTP(
          type: OtpType.emailChange,
          email: email.trim(),
          token: token.trim(),
        );
      });

  @override
  Future<void> signInWithApple() => guard(() async {
        if (!Env.appleSignInEnabled) {
          throw const AuthFailure('Apple sign-in is not configured yet');
        }

        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)) {
          final rawNonce = _auth.generateRawNonce();
          final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

          final credential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: hashedNonce,
          );

          final idToken = credential.identityToken;
          if (idToken == null) {
            throw const AuthFailure('Apple did not return an identity token');
          }

          await _auth.signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: idToken,
            nonce: rawNonce,
          );
          return;
        }

        await _auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: Env.oauthRedirectUrl,
        );
      });

  @override
  Future<void> signInWithGoogle() => guard(() async {
        if (!Env.googleSignInEnabled) {
          throw const AuthFailure('Google sign-in is not configured yet');
        }

        if (kIsWeb) {
          await _auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: Env.oauthRedirectUrl,
          );
          return;
        }

        final serverClientId = Env.googleServerClientId;
        if (serverClientId == null) {
          throw const AuthFailure(
            'GOOGLE_SERVER_CLIENT_ID is missing from assets/.env',
          );
        }

        _googleInit ??= GoogleSignIn.instance.initialize(
          clientId: Env.googleIosClientId,
          serverClientId: serverClientId,
        );
        await _googleInit;

        final account = await GoogleSignIn.instance.authenticate(
          scopeHint: const ['email', 'profile'],
        );
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          throw const AuthFailure('Google did not return an identity token');
        }

        await _auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
      });

  @override
  Future<void> signOut() => guard(() async {
        await _auth.signOut();
      });
}
