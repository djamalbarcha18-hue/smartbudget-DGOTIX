import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/auth/domain/google_nonce.dart';

/// Google gets the SHA-256 of the nonce; the server gets the raw value and
/// checks that they match.
void main() {
  test('the hash is the lower-case hex SHA-256 of the raw value', () {
    expect(GoogleNonce.hashOf('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });

  test('a fresh nonce is random, url-safe and hashed', () {
    final GoogleNonce a = GoogleNonce.create();
    final GoogleNonce b = GoogleNonce.create();
    expect(a.raw, isNot(b.raw));
    expect(a.raw.length, greaterThanOrEqualTo(40));
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(a.raw), isTrue);
    expect(a.hashed, GoogleNonce.hashOf(a.raw));
    expect(a.hashed, hasLength(64));
  });

  test('the same randomness gives the same nonce', () {
    expect(GoogleNonce.create(Random(7)).raw, GoogleNonce.create(Random(7)).raw);
  });
}
