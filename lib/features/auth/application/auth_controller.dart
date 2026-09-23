import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/auth/data/fake_auth_repository.dart';
import 'package:smartbudget/features/auth/data/supabase_auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_user.dart';

/// Binds the active [AuthRepository]: real Supabase when configured, else the
/// local dev backend (fake). This is the single switch between demo and
/// production — no UI or business code depends on the concrete backend.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final AuthRepository repo =
      AppEnv.hasSupabase ? SupabaseAuthRepository() : FakeAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

enum AuthStatus { unknown, authenticated, unauthenticated }

@immutable
class AuthState {
  const AuthState({required this.status, this.user});

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null;

  final AuthStatus status;
  final AuthUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState _resolved(AuthUser? user) => AuthState(
        status: user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
      );
}

/// Holds auth state and exposes the auth actions to the UI. Actions throw
/// [AuthFailure] on error; state itself is driven by the repository stream, so
/// there is a single source of truth for "who is signed in".
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final AuthRepository repo = ref.watch(authRepositoryProvider);
    final StreamSubscription<AuthUser?> sub =
        repo.authStateChanges().listen((AuthUser? user) {
      state = state._resolved(user);
    });
    ref.onDispose(sub.cancel);
    return const AuthState.unknown();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signIn({required String email, required String password}) =>
      _repo.signIn(email: email, password: password);

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _repo.signUp(email: email, password: password, displayName: displayName);

  Future<void> signOut() => _repo.signOut();

  Future<void> sendPasswordReset({required String email}) =>
      _repo.sendPasswordReset(email: email);

  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _repo.resetPasswordWithCode(
          email: email, code: code, newPassword: newPassword);
}
