/// Domain-level auth error, decoupled from any backend SDK.
///
/// Data-layer implementations map provider exceptions into these cases so the
/// UI never depends on Supabase (or fake) error types.
enum AuthFailureKind {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  userNotFound,
  invalidCode,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, [this.rawMessage]);

  final AuthFailureKind kind;
  final String? rawMessage;

  @override
  String toString() => 'AuthFailure(${kind.name})';
}
