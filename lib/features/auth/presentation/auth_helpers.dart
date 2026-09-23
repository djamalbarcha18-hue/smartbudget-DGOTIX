import 'package:smartbudget/features/auth/domain/auth_failure.dart';
import 'package:smartbudget/features/auth/domain/password_policy.dart';
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

  /// Sign-in: only require a value. Existing users may have passwords created
  /// under older rules and must never be locked out.
  static String? password(String? value, AppLocalizations l) {
    if ((value ?? '').isEmpty) return l.valRequired;
    return null;
  }

  /// New passwords (sign-up, reset): 8+ chars with a letter, digit and symbol.
  static String? newPassword(String? value, AppLocalizations l) {
    final String v = value ?? '';
    if (v.isEmpty) return l.valRequired;
    final PasswordCheck c = PasswordPolicy.check(v);
    if (!c.hasNoSpaces) return l.valPasswordSpaces;
    if (!c.isStrong) return l.valPasswordWeak;
    return null;
  }

  static String? confirmPassword(
      String? value, String original, AppLocalizations l) {
    if ((value ?? '').isEmpty) return l.valRequired;
    if (value != original) return l.valPasswordMismatch;
    return null;
  }

  /// The emailed recovery code: digits only (Supabase sends 6–10).
  static String? code(String? value, AppLocalizations l) {
    final String v = (value ?? '').trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(v)) return l.valCode;
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
    AuthFailureKind.invalidCode => l.authErrInvalidCode,
    AuthFailureKind.network => l.authErrNetwork,
    AuthFailureKind.unknown => l.authErrUnknown,
  };
}
