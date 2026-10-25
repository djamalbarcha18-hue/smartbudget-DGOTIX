import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:smartbudget/features/quick_entry/data/shared_text_web_stub.dart'
    if (dart.library.js_interop) 'package:smartbudget/features/quick_entry/data/shared_text_web.dart'
    as web;

/// Text another app shared with SmartBudget ("Share" on a bank message):
/// Android's share sheet, or the installed web app's share target. The app
/// only ever sees what the user chose to share.
abstract final class SharedText {
  static const MethodChannel _channel =
      MethodChannel('smartbudget/shared_text');

  /// Bumped when text is shared while the app is already open.
  static final ValueNotifier<int> arrived = ValueNotifier<int>(0);

  static bool _listening = false;

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The shared text not handled yet (then forgotten), or null.
  static Future<String?> take() async {
    if (kIsWeb) return web.takeSharedText();
    if (!_android) return null;
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'shared') arrived.value++;
      });
    }
    try {
      return await _channel.invokeMethod<String>('take');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
