import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

enum InstallMode { none, prompt, iosHint, installed }

JSObject get _window => globalContext;

bool _standalone() {
  try {
    final JSObject mq = _window.callMethod<JSObject>(
        'matchMedia'.toJS, '(display-mode: standalone)'.toJS);
    if ((mq['matches'] as JSBoolean?)?.toDart ?? false) return true;
    final JSObject nav = _window['navigator']! as JSObject;
    return (nav['standalone'] as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

bool _ios() {
  final JSObject nav = _window['navigator']! as JSObject;
  final String ua = (nav['userAgent'] as JSString?)?.toDart ?? '';
  final int touch = (nav['maxTouchPoints'] as JSNumber?)?.toDartInt ?? 0;
  return RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && touch > 1);
}

JSObject? get _prompt {
  final JSAny? p = _window['sbInstallPrompt'];
  return p.isUndefinedOrNull ? null : p as JSObject;
}

InstallMode installMode() {
  if (_standalone() ||
      ((_window['sbInstalled'] as JSBoolean?)?.toDart ?? false)) {
    return InstallMode.installed;
  }
  if (_prompt != null) return InstallMode.prompt;
  if (_ios()) return InstallMode.iosHint;
  return InstallMode.none;
}

/// Shows the browser's install dialog. True when the user accepts.
Future<bool> promptInstall() async {
  final JSObject? e = _prompt;
  if (e == null) return false;
  try {
    e.callMethod<JSAny?>('prompt'.toJS);
    final JSObject choice =
        await (e['userChoice']! as JSPromise<JSObject>).toDart;
    _window['sbInstallPrompt'] = null;
    _window.callMethod<JSAny?>(
        'dispatchEvent'.toJS,
        (globalContext['Event']! as JSFunction)
            .callAsConstructor<JSObject>('sbinstallchange'.toJS));
    return (choice['outcome'] as JSString?)?.toDart == 'accepted';
  } catch (_) {
    return false;
  }
}

Stream<void> installChanges() {
  late final StreamController<void> ctl;
  final JSFunction listener = ((JSAny? _) => ctl.add(null)).toJS;
  ctl = StreamController<void>.broadcast(
    onListen: () => _window.callMethod<JSAny?>(
        'addEventListener'.toJS, 'sbinstallchange'.toJS, listener),
    onCancel: () => _window.callMethod<JSAny?>(
        'removeEventListener'.toJS, 'sbinstallchange'.toJS, listener),
  );
  return ctl.stream;
}
