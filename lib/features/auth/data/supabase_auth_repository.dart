import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:smartbudget/features/auth/domain/auth_failure.dart';
import 'package:smartbudget/features/auth/domain/auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_user.dart';

/// Real authentication backed by Supabase.
///
/// Bound only when SUPABASE_URL/ANON_KEY are configured (see AppEnv). Provider
/// exceptions are mapped to the backend-agnostic [AuthFailure] so the UI never
/// depends on the Supabase SDK.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository() : _client = sb.Supabase.instance.client;

  final sb.SupabaseClient _client;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((sb.AuthState s) => _map(s.session?.user));

  @override
  AuthUser? get currentUser => _map(_client.auth.currentUser);

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    try {
      final sb.AuthResponse res = await _client.auth.signInWithPassword(
          email: email.trim(), password: password, captchaToken: captchaToken);
      final AuthUser? user = _map(res.user);
      if (user == null) throw const AuthFailure(AuthFailureKind.unknown);
      return user;
    } on sb.AuthException catch (e) {
      throw _failure(e);
    } catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, e.toString());
    }
  }

  @override
  Future<AuthUser?> signUp({
    required String email,
    required String password,
    String? displayName,
    String? captchaToken,
  }) async {
    try {
      final sb.AuthResponse res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        captchaToken: captchaToken,
        data: displayName != null && displayName.trim().isNotEmpty
            ? <String, dynamic>{'display_name': displayName.trim()}
            : null,
      );
      final sb.User? created = res.user;
      if (created == null) throw const AuthFailure(AuthFailureKind.unknown);
      // With e-mail confirmation on, signing up an address that already has
      // an account returns a placeholder user with no identities (and sends
      // nothing) instead of an error.
      if (created.identities?.isEmpty ?? false) {
        throw const AuthFailure(AuthFailureKind.emailAlreadyInUse);
      }
      // No session yet: the confirmation link must be opened first.
      if (res.session == null) return null;
      return _map(created);
    } on sb.AuthException catch (e) {
      throw _failure(e);
    } catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, e.toString());
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> sendPasswordReset(
      {required String email, String? captchaToken}) async {
    try {
      await _client.auth
          .resetPasswordForEmail(email.trim(), captchaToken: captchaToken);
    } on sb.AuthException catch (e) {
      throw _failure(e);
    } catch (e) {
      throw AuthFailure(AuthFailureKind.unknown, e.toString());
    }
  }

  @override
  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    // 1) Prove ownership of the email with the one-time recovery code. This
    //    opens a short recovery session.
    try {
      await _client.auth.verifyOTP(
        type: sb.OtpType.recovery,
        email: email.trim(),
        token: code.trim(),
      );
    } on sb.AuthException catch (e) {
      throw AuthFailure(AuthFailureKind.invalidCode, e.message);
    } catch (e) {
      throw AuthFailure(AuthFailureKind.network, e.toString());
    }

    // 2) Set the new password inside that session.
    try {
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (e) {
      // Don't leave a half-finished recovery session signed in.
      await _safeSignOut();
      throw AuthFailure(AuthFailureKind.weakPassword, e.message);
    } catch (e) {
      await _safeSignOut();
      throw AuthFailure(AuthFailureKind.unknown, e.toString());
    }
  }

  Future<void> _safeSignOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  void dispose() {}

  AuthUser? _map(sb.User? u) {
    if (u == null || u.email == null) return null;
    final Object? name = u.userMetadata?['display_name'];
    return AuthUser(
      id: u.id,
      email: u.email!,
      displayName: name is String ? name : null,
    );
  }

  AuthFailure _failure(sb.AuthException e) {
    final String msg = e.message.toLowerCase();
    if (msg.contains('captcha')) {
      return AuthFailure(AuthFailureKind.captchaFailed, e.message);
    }
    if (msg.contains('already registered') || msg.contains('already in use')) {
      return AuthFailure(AuthFailureKind.emailAlreadyInUse, e.message);
    }
    if (msg.contains('not confirmed')) {
      return AuthFailure(AuthFailureKind.emailNotConfirmed, e.message);
    }
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return AuthFailure(AuthFailureKind.invalidCredentials, e.message);
    }
    if (msg.contains('token') || msg.contains('otp') || msg.contains('expired')) {
      return AuthFailure(AuthFailureKind.invalidCode, e.message);
    }
    if (msg.contains('password')) {
      return AuthFailure(AuthFailureKind.weakPassword, e.message);
    }
    if (msg.contains('not found')) {
      return AuthFailure(AuthFailureKind.userNotFound, e.message);
    }
    if (msg.contains('network') || msg.contains('timeout')) {
      return AuthFailure(AuthFailureKind.network, e.message);
    }
    return AuthFailure(AuthFailureKind.unknown, e.message);
  }
}
