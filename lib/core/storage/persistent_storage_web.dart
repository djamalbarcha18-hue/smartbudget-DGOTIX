// Web implementation (StorageManager.persist). Kept behind a conditional
// import (see persistent_storage.dart) so nothing else reaches for the DOM.
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Requests persistent storage. Returns true when storage is (now) persistent.
/// Browsers may grant it silently, prompt, or refuse; any failure is non-fatal.
Future<bool> requestPersistentStorage() async {
  try {
    // A browser without the Storage API throws on the getter; that is the
    // "not supported" answer and the catch below turns it into false.
    final web.StorageManager sm = web.window.navigator.storage;
    if ((await sm.persisted().toDart).toDart) return true;
    return (await sm.persist().toDart).toDart;
  } catch (_) {
    return false;
  }
}

/// Whether storage is already persistent; null when unsupported.
Future<bool?> isStoragePersisted() async {
  try {
    final web.StorageManager sm = web.window.navigator.storage;
    return (await sm.persisted().toDart).toDart;
  } catch (_) {
    return null;
  }
}
