import 'package:idb_shim/idb_client_native.dart';

/// Never the in-memory stand-in (idbFactoryBrowser falls back to one): data
/// kept there would vanish on reload while looking saved.
Future<IdbFactory?> deviceIdbFactory() async {
  try {
    return idbFactoryNative;
  } catch (_) {
    return null;
  }
}
