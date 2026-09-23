/// Strong-password policy for NEW passwords (sign-up and password reset).
///
/// At least 8 characters with a letter, a digit and a symbol. Sign-in does NOT
/// apply this — existing users with older passwords must never be locked out.
/// The same rules should also be enabled server-side in Supabase (see
/// docs/SUPABASE_SETUP.md), because a client check alone can be bypassed.
library;

class PasswordCheck {
  const PasswordCheck({
    required this.hasMinLength,
    required this.hasLetter,
    required this.hasDigit,
    required this.hasSymbol,
    required this.hasNoSpaces,
  });

  final bool hasMinLength;
  final bool hasLetter;
  final bool hasDigit;
  final bool hasSymbol;
  final bool hasNoSpaces;

  bool get isStrong =>
      hasMinLength && hasLetter && hasDigit && hasSymbol && hasNoSpaces;

  /// How many of the four visible rules are met (0..4), for a strength meter.
  int get score => <bool>[hasMinLength, hasLetter, hasDigit, hasSymbol]
      .where((bool b) => b)
      .length;
}

abstract final class PasswordPolicy {
  static const int minLength = 8;

  // ASCII classes, matching what Supabase's server-side password rules count
  // as letters, digits and symbols — so the app never accepts a password the
  // server would then reject.
  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _symbol = RegExp(r'[!-/:-@\[-`{-~]');
  static final RegExp _space = RegExp(r'\s');

  static PasswordCheck check(String password) => PasswordCheck(
        hasMinLength: password.length >= minLength,
        hasLetter: _letter.hasMatch(password),
        hasDigit: _digit.hasMatch(password),
        hasSymbol: _symbol.hasMatch(password),
        hasNoSpaces: !_space.hasMatch(password),
      );
}
