import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/auth/data/fake_auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_failure.dart';
import 'package:smartbudget/features/auth/domain/password_policy.dart';

void main() {
  group('PasswordPolicy', () {
    test('accepts 8+ chars with a letter, a digit and a symbol', () {
      expect(PasswordPolicy.check('abc123!@').isStrong, isTrue);
      expect(PasswordPolicy.check('Budget2026#').isStrong, isTrue);
    });

    test('rejects each missing rule', () {
      expect(PasswordPolicy.check('ab1!').hasMinLength, isFalse); // too short
      expect(PasswordPolicy.check('12345678!').hasLetter, isFalse);
      expect(PasswordPolicy.check('abcdefgh!').hasDigit, isFalse);
      expect(PasswordPolicy.check('abcd1234').hasSymbol, isFalse);
      expect(PasswordPolicy.check('abc 123!x').hasNoSpaces, isFalse);
      for (final String weak in <String>[
        'ab1!', '12345678!', 'abcdefgh!', 'abcd1234', 'abc 123!x',
      ]) {
        expect(PasswordPolicy.check(weak).isStrong, isFalse, reason: weak);
      }
    });

    test('symbols are the same ASCII set Supabase counts', () {
      for (final String s in r'!@#$%^&*()_+-=[]{};' "'" r'\:"|<>?,./`~'.split('')) {
        expect(PasswordPolicy.check('abcd1234$s').hasSymbol, isTrue,
            reason: 'symbol $s');
      }
    });

    test('score counts the four visible rules', () {
      expect(PasswordPolicy.check('').score, 0);
      expect(PasswordPolicy.check('abcdefgh').score, 2); // length + letter
      expect(PasswordPolicy.check('abc123!@').score, 4);
    });
  });

  group('Recovery with an emailed code (dev fake)', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    Future<AuthFailureKind?> attempt(
      FakeAuthRepository repo, {
      String email = 'user@example.com',
      String code = '123456',
      String password = 'NewPass1!',
    }) async {
      try {
        await repo.resetPasswordWithCode(
            email: email, code: code, newPassword: password);
        return null;
      } on AuthFailure catch (f) {
        return f.kind;
      }
    }

    test('succeeds and signs the user in', () async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await repo.sendPasswordReset(email: 'user@example.com');
      expect(await attempt(repo), isNull);
      expect(repo.currentUser?.email, 'user@example.com');
      repo.dispose();
    });

    test('rejects a code for an email that never asked for one', () async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await repo.sendPasswordReset(email: 'user@example.com');
      expect(await attempt(repo, email: 'other@example.com'),
          AuthFailureKind.invalidCode);
      repo.dispose();
    });

    test('rejects a malformed code', () async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await repo.sendPasswordReset(email: 'user@example.com');
      expect(await attempt(repo, code: '12ab'), AuthFailureKind.invalidCode);
      repo.dispose();
    });

    test('rejects a weak new password', () async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await repo.sendPasswordReset(email: 'user@example.com');
      expect(await attempt(repo, password: 'password'),
          AuthFailureKind.weakPassword);
      repo.dispose();
    });

    test('a code works only once', () async {
      final FakeAuthRepository repo = FakeAuthRepository();
      await repo.sendPasswordReset(email: 'user@example.com');
      expect(await attempt(repo), isNull);
      expect(await attempt(repo), AuthFailureKind.invalidCode);
      repo.dispose();
    });
  });
}
