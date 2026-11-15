import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/auth/domain/auth_user.dart';
import 'package:smartbudget/features/shell/user_avatar.dart';

void main() {
  group('Google account picture address', () {
    test('a picture served by Google over https is accepted', () {
      const String url = 'https://lh3.googleusercontent.com/a/abc123=s96-c';
      expect(AuthUser.googleAvatarUrl(url), url);
      expect(AuthUser.googleAvatarUrl('  $url '), url);
    });

    test('anything else is ignored, so the initial is shown', () {
      expect(AuthUser.googleAvatarUrl(null), isNull);
      expect(AuthUser.googleAvatarUrl(42), isNull);
      expect(AuthUser.googleAvatarUrl(''), isNull);
      expect(AuthUser.googleAvatarUrl('http://lh3.googleusercontent.com/a/x'),
          isNull);
      expect(AuthUser.googleAvatarUrl('https://evil.example/a.png'), isNull);
      expect(
          AuthUser.googleAvatarUrl(
              'https://lh3.googleusercontent.com.evil.example/a'),
          isNull);
      expect(
          AuthUser.googleAvatarUrl(
              'https://user@lh3.googleusercontent.com/a/x'),
          isNull);
      expect(AuthUser.googleAvatarUrl('javascript:alert(1)'), isNull);
    });

    test('the picture is part of the user\'s identity', () {
      const AuthUser a = AuthUser(id: 'u', email: 'a@test');
      const AuthUser b = AuthUser(
          id: 'u',
          email: 'a@test',
          avatarUrl: 'https://lh3.googleusercontent.com/a/x');
      expect(a == b, isFalse);
    });
  });

  group('initial shown without a picture', () {
    test('first letter of the name, upper-cased', () {
      expect(UserAvatar.initialOf('djamal'), 'D');
      expect(UserAvatar.initialOf('  sara ali'), 'S');
      expect(UserAvatar.initialOf('جمال'), 'ج');
    });

    test('no name gives no letter (a person icon is drawn)', () {
      expect(UserAvatar.initialOf(null), '');
      expect(UserAvatar.initialOf('   '), '');
    });
  });
}
