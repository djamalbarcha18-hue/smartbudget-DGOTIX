import 'package:smartbudget/features/auth/domain/auth_user.dart';

/// Backend-agnostic authentication contract.
///
/// The presentation/application layers depend ONLY on this interface. Swapping
/// the fake dev backend for Supabase (or any other provider) is a one-line
/// provider override — no UI or business code changes.
abstract interface class AuthRepository {
  /// Emits the current user (or null when signed out) and every change after.
  Stream<AuthUser?> authStateChanges();

  /// The currently cached user, if any (synchronous best-effort).
  AuthUser? get currentUser;

  /// Throws [AuthFailure] on error.
  Future<AuthUser> signIn({required String email, required String password});

  /// Throws [AuthFailure] on error.
  Future<AuthUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> signOut();

  /// Emails a one-time recovery code to [email]. Throws [AuthFailure] on
  /// error. For privacy it succeeds whether or not an account exists.
  Future<void> sendPasswordReset({required String email});

  /// Verifies the emailed recovery [code] and sets [newPassword]. On success
  /// the user is signed in. Throws [AuthFailure] ([AuthFailureKind.invalidCode]
  /// for a wrong/expired code, [AuthFailureKind.weakPassword] if the server
  /// rejects the password).
  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Release resources (close streams). Called on provider dispose.
  void dispose();
}
