import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// The one-time value tying a Google ID token to this sign-in: Google gets
/// [hashed] (it is written into the token), the server gets [raw] and checks
/// that its SHA-256 matches. A token taken from elsewhere can't be replayed.
class GoogleNonce {
  GoogleNonce._(this.raw) : hashed = hashOf(raw);

  /// A fresh random value.
  factory GoogleNonce.create([Random? random]) {
    final Random r = random ?? Random.secure();
    final List<int> bytes = List<int>.generate(32, (_) => r.nextInt(256));
    return GoogleNonce._(base64UrlEncode(bytes).replaceAll('=', ''));
  }

  final String raw;
  final String hashed;

  /// Lower-case hex SHA-256, as the server compares it.
  static String hashOf(String raw) => sha256.convert(utf8.encode(raw)).toString();
}
