import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/auth/domain/auth_failure.dart';
import 'package:smartbudget/features/auth/domain/auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_user.dart';

/// In-memory / device-local authentication for DEVELOPMENT ONLY.
///
/// It enables the full auth UX (sign in / up / out, guarded routing, persisted
/// session) with no backend. It performs only shape validation — it is NOT
/// secure and never reaches a server. The real [AuthRepository] is Supabase,
/// bound automatically once SUPABASE_URL/ANON_KEY are provided.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository() {
    _controller = StreamController<AuthUser?>.broadcast(
      onListen: _emitInitial,
    );
  }

  static const String _kUid = 'sb_auth_uid';
  static const String _kEmail = 'sb_auth_email';
  static const String _kName = 'sb_auth_name';

  late final StreamController<AuthUser?> _controller;
  AuthUser? _current;
  bool _restored = false;

  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  Future<void> _emitInitial() async {
    await _restoreSession();
    if (!_controller.isClosed) _controller.add(_current);
  }

  Future<void> _restoreSession() async {
    if (_restored) return;
    _restored = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? uid = prefs.getString(_kUid);
      final String? email = prefs.getString(_kEmail);
      if (uid != null && email != null) {
        _current = AuthUser(
          id: uid,
          email: email,
          displayName: prefs.getString(_kName),
        );
      }
    } catch (_) {
      // No stored session — stay signed out.
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _validate(email, password);
    final AuthUser user = AuthUser(id: _idFor(email), email: email.trim());
    await _persist(user);
    return user;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _validate(email, password);
    final AuthUser user = AuthUser(
      id: _idFor(email),
      email: email.trim(),
      displayName: displayName?.trim(),
    );
    await _persist(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUid);
      await prefs.remove(_kEmail);
      await prefs.remove(_kName);
    } catch (_) {
      // Non-fatal.
    }
    if (!_controller.isClosed) _controller.add(null);
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!_isEmail(email)) {
      throw const AuthFailure(AuthFailureKind.userNotFound);
    }
    // Dev fake: nothing to send.
  }

  @override
  void dispose() {
    _controller.close();
  }

  // ---- helpers ----

  void _validate(String email, String password) {
    if (!_isEmail(email)) {
      throw const AuthFailure(AuthFailureKind.invalidCredentials);
    }
    if (password.trim().length < 6) {
      throw const AuthFailure(AuthFailureKind.weakPassword);
    }
  }

  Future<void> _persist(AuthUser user) async {
    _current = user;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUid, user.id);
      await prefs.setString(_kEmail, user.email);
      if (user.displayName != null) {
        await prefs.setString(_kName, user.displayName!);
      } else {
        await prefs.remove(_kName);
      }
    } catch (_) {
      // Session simply won't survive reload — non-fatal for dev.
    }
    if (!_controller.isClosed) _controller.add(user);
  }

  bool _isEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  String _idFor(String email) => 'dev-${email.trim().toLowerCase().hashCode}';
}
