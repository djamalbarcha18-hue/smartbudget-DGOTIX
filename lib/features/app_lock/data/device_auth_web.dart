// WebAuthn platform authenticator + page reload, behind a conditional import.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:typed_data';

JSObject? get _publicKeyCredential =>
    globalContext.has('PublicKeyCredential')
        ? globalContext['PublicKeyCredential'] as JSObject?
        : null;

JSObject get _credentials =>
    (globalContext['navigator']! as JSObject)['credentials']! as JSObject;

Uint8List _random(int n) {
  final Random r = Random.secure();
  return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
}

Future<bool> deviceAuthAvailable() async {
  final JSObject? pkc = _publicKeyCredential;
  if (pkc == null ||
      !pkc.has('isUserVerifyingPlatformAuthenticatorAvailable')) {
    return false;
  }
  try {
    final JSBoolean ok = await pkc
        .callMethod<JSPromise<JSBoolean>>(
            'isUserVerifyingPlatformAuthenticatorAvailable'.toJS)
        .toDart;
    return ok.toDart;
  } catch (_) {
    return false;
  }
}

/// Creates a platform credential and returns its id (base64url), or null if
/// the user cancels or the device can't.
Future<String?> registerDeviceAuth({required String userName}) async {
  try {
    final JSObject rp = JSObject()..['name'] = 'SmartBudget'.toJS;
    final JSObject user = JSObject()
      ..['id'] = _random(16).toJS
      ..['name'] = userName.toJS
      ..['displayName'] = userName.toJS;
    final JSObject es256 = JSObject()
      ..['type'] = 'public-key'.toJS
      ..['alg'] = (-7).toJS;
    final JSObject rs256 = JSObject()
      ..['type'] = 'public-key'.toJS
      ..['alg'] = (-257).toJS;
    final JSObject selection = JSObject()
      ..['authenticatorAttachment'] = 'platform'.toJS
      ..['userVerification'] = 'required'.toJS
      ..['residentKey'] = 'discouraged'.toJS;
    final JSObject publicKey = JSObject()
      ..['challenge'] = _random(32).toJS
      ..['rp'] = rp
      ..['user'] = user
      ..['pubKeyCredParams'] = <JSAny>[es256, rs256].toJS
      ..['authenticatorSelection'] = selection
      ..['timeout'] = 60000.toJS
      ..['attestation'] = 'none'.toJS;
    final JSObject? cred = await _credentials
        .callMethod<JSPromise<JSObject?>>(
            'create'.toJS, JSObject()..['publicKey'] = publicKey)
        .toDart;
    if (cred == null) return null;
    final ByteBuffer raw = (cred['rawId']! as JSArrayBuffer).toDart;
    return base64Url.encode(raw.asUint8List());
  } catch (_) {
    return null;
  }
}

/// Asks the device to verify the user (fingerprint / face / device PIN) for
/// [credentialId]. True only when the device confirms.
Future<bool> verifyDeviceAuth(String credentialId) async {
  try {
    final JSObject allow = JSObject()
      ..['type'] = 'public-key'.toJS
      ..['id'] = base64Url.decode(credentialId).toJS;
    final JSObject publicKey = JSObject()
      ..['challenge'] = _random(32).toJS
      ..['allowCredentials'] = <JSAny>[allow].toJS
      ..['userVerification'] = 'required'.toJS
      ..['timeout'] = 60000.toJS;
    final JSObject? assertion = await _credentials
        .callMethod<JSPromise<JSObject?>>(
            'get'.toJS, JSObject()..['publicKey'] = publicKey)
        .toDart;
    return assertion != null;
  } catch (_) {
    return false;
  }
}

void reloadApp() {
  ((globalContext['location']! as JSObject)).callMethod<JSAny?>('reload'.toJS);
}
