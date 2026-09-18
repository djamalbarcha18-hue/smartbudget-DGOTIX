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

  /// Sends a password-reset email. Throws [AuthFailure] on error.
  Future<void> sendPasswordReset({required String email});

  /// Release resources (close streams). Called on provider dispose.
  void dispose();
}
