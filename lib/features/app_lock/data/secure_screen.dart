import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android only: keeps the app's screens out of the recent-apps preview and
/// of screenshots while the app lock is on (FLAG_SECURE, see MainActivity).
abstract final class SecureScreen {
  static const MethodChannel _channel =
      MethodChannel('smartbudget/secure_screen');

  static Future<void> set(bool on) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecure', on);
    } catch (_) {
      // Older builds without the channel: nothing to do.
    }
  }
}
