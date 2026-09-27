import 'package:flutter/foundation.dart';

/// The app's single source of "now".
///
/// It is the device clock corrected by the offset measured against network
/// time (UTC), so a wrong or changed device clock can't shift the current
/// month, due dates, recurring posts, goal deadlines or a trial's expiry.
/// Without a sync (offline, tests) it is simply the device clock.
abstract final class AppClock {
  static Duration _offset = Duration.zero;
  static DateTime? _syncedAt;

  /// Differences this small are noise: the HTTP `Date` header has one-second
  /// resolution and the request itself takes time.
  static const Duration tolerance = Duration(seconds: 3);

  static DateTime now() => DateTime.now().add(_offset);

  /// How far the device clock is behind (+) or ahead (−) of world time.
  static Duration get offset => _offset;

  /// When the last successful sync happened (corrected time), or null.
  static DateTime? get syncedAt => _syncedAt;

  static bool get isSynced => _syncedAt != null;

  static void applyOffset(Duration measured) {
    _offset = measured.abs() <= tolerance ? Duration.zero : measured;
    _syncedAt = now();
  }

  /// Offset from one request: the server's clock is compared with the device
  /// clock at the midpoint of the round trip. The header is truncated to the
  /// second, so the true server time is on average half a second later.
  static Duration measure({
    required DateTime serverUtc,
    required DateTime sentAt,
    required DateTime receivedAt,
  }) {
    final DateTime midpoint =
        sentAt.add(receivedAt.difference(sentAt) ~/ 2);
    return serverUtc
        .add(const Duration(milliseconds: 500))
        .difference(midpoint);
  }

  @visibleForTesting
  static void reset() {
    _offset = Duration.zero;
    _syncedAt = null;
  }
}
