import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Device-level app-lock settings. The PIN itself is never stored: only a
/// salted, iterated SHA-256 of it.
class LockConfig {
  const LockConfig({
    this.pinHash,
    this.salt,
    this.pinLength = 0,
    this.credentialId,
    this.autoLockMinutes = 1,
    this.recoveryHash,
    this.recoverySalt,
  });

  final String? pinHash;
  final String? salt;

  /// Lets the lock screen submit as soon as the last digit is typed.
  final int pinLength;

  /// WebAuthn credential for unlocking with the device (fingerprint / face).
  final String? credentialId;

  /// Lock again after the app has been in the background this long
  /// (0 = immediately).
  final int autoLockMinutes;

  /// "Forgot PIN" recovery code, stored like the PIN (salted, iterated hash).
  final String? recoveryHash;
  final String? recoverySalt;

  static const List<int> autoLockChoices = <int>[0, 1, 5, 15];

  bool get enabled => pinHash != null && salt != null && pinLength > 0;
  bool get deviceUnlock => enabled && credentialId != null;
  bool get hasRecovery =>
      enabled && recoveryHash != null && recoverySalt != null;

  LockConfig copyWith({
    String? credentialId,
    bool clearCredential = false,
    int? autoLockMinutes,
  }) =>
      LockConfig(
        pinHash: pinHash,
        salt: salt,
        pinLength: pinLength,
        credentialId: clearCredential ? null : credentialId ?? this.credentialId,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
        recoveryHash: recoveryHash,
        recoverySalt: recoverySalt,
      );

  LockConfig withPin(String pin, {Random? random}) {
    final String s = PinHasher.newSalt(random);
    return LockConfig(
      pinHash: PinHasher.hash(pin, s),
      salt: s,
      pinLength: pin.length,
      credentialId: credentialId,
      autoLockMinutes: autoLockMinutes,
      recoveryHash: recoveryHash,
      recoverySalt: recoverySalt,
    );
  }

  /// Replaces the recovery code with [code] (a new one invalidates the old).
  LockConfig withRecovery(String code, {Random? random}) {
    final String s = PinHasher.newSalt(random);
    return LockConfig(
      pinHash: pinHash,
      salt: salt,
      pinLength: pinLength,
      credentialId: credentialId,
      autoLockMinutes: autoLockMinutes,
      recoveryHash: PinHasher.hash(RecoveryCode.normalize(code), s),
      recoverySalt: s,
    );
  }

  bool matches(String pin) =>
      enabled && PinHasher.verify(pin, salt!, pinHash!);

  bool matchesRecovery(String code) {
    if (!hasRecovery) return false;
    final String n = RecoveryCode.normalize(code);
    return RecoveryCode.isWellFormed(n) &&
        PinHasher.verify(n, recoverySalt!, recoveryHash!);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pinHash': pinHash,
        'salt': salt,
        'pinLength': pinLength,
        'credentialId': credentialId,
        'autoLockMinutes': autoLockMinutes,
        'recoveryHash': recoveryHash,
        'recoverySalt': recoverySalt,
      };

  factory LockConfig.fromJson(Map<String, dynamic> j) => LockConfig(
        pinHash: j['pinHash'] as String?,
        salt: j['salt'] as String?,
        pinLength: (j['pinLength'] as num?)?.toInt() ?? 0,
        credentialId: j['credentialId'] as String?,
        autoLockMinutes: (j['autoLockMinutes'] as num?)?.toInt() ?? 1,
        recoveryHash: j['recoveryHash'] as String?,
        recoverySalt: j['recoverySalt'] as String?,
      );
}

abstract final class PinHasher {
  static const int iterations = 10000;

  static bool isValid(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

  static String newSalt([Random? random]) {
    final Random r = random ?? Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String hash(String pin, String salt) {
    final List<int> saltBytes = utf8.encode(salt);
    List<int> h = utf8.encode('$salt:$pin');
    for (int i = 0; i < iterations; i++) {
      h = sha256.convert(<int>[...saltBytes, ...h]).bytes;
    }
    return base64Url.encode(h);
  }

  static bool verify(String pin, String salt, String expected) {
    final String actual = hash(pin, salt);
    if (actual.length != expected.length) return false;
    int diff = 0;
    for (int i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// The one-time "forgot PIN" code shown when the lock is set up, e.g.
/// `K7QM-2XPA-9RTD`: 12 characters from 32 unambiguous ones (no 0/O, 1/I),
/// about 60 bits — with the lock-out below, it can't be guessed.
abstract final class RecoveryCode {
  static const String alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const int length = 12;

  static String generate([Random? random]) {
    final Random r = random ?? Random.secure();
    final String raw = String.fromCharCodes(List<int>.generate(
        length, (_) => alphabet.codeUnitAt(r.nextInt(alphabet.length))));
    return format(raw);
  }

  /// `K7QM2XPA9RTD` → `K7QM-2XPA-9RTD`.
  static String format(String normalized) => <String>[
        for (int i = 0; i < normalized.length; i += 4)
          normalized.substring(i, min(i + 4, normalized.length)),
      ].join('-');

  /// Upper-case, without the spaces and dashes people type in.
  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[\s\-_.]'), '');

  static bool isWellFormed(String normalized) =>
      normalized.length == length &&
      normalized.split('').every(alphabet.contains);
}

/// Wait imposed after repeated wrong PINs: none for the first 4, then 30 s
/// doubling each time, capped at 15 minutes.
Duration lockoutAfter(int failures) {
  if (failures < 5) return Duration.zero;
  final int seconds = 30 * (1 << min(failures - 5, 5));
  return Duration(seconds: min(seconds, 15 * 60));
}
