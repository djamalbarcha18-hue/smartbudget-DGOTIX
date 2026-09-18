import 'package:smartbudget/features/auth/domain/auth_failure.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Field validators (return null when valid).
abstract final class AuthValidators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value, AppLocalizations l) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return l.valRequired;
    if (!_email.hasMatch(v)) return l.valEmail;
    return null;
  }

  static String? password(String? value, AppLocalizations l) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return l.valRequired;
    if (v.length < 6) return l.valPasswordShort;
    return null;
  }

  static String? required(String? value, AppLocalizations l) {
    if ((value ?? '').trim().isEmpty) return l.valRequired;
    return null;
  }
}

/// Maps a backend-agnostic [AuthFailure] to a localized, user-facing message.
String authFailureMessage(Object error, AppLocalizations l) {
  if (error is! AuthFailure) return l.authErrUnknown;
  return switch (error.kind) {
    AuthFailureKind.invalidCredentials => l.authErrInvalid,
    AuthFailureKind.emailAlreadyInUse => l.authErrEmailInUse,
    AuthFailureKind.weakPassword => l.authErrWeak,
    AuthFailureKind.userNotFound => l.authErrUserNotFound,
    AuthFailureKind.network => l.authErrNetwork,
    AuthFailureKind.unknown => l.authErrUnknown,
  };
}
