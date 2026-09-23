// Web implementation (StorageManager.persist). Kept behind a conditional
// import (see persistent_storage.dart) so nothing else imports dart:html.
import 'dart:html' as html;

/// Requests persistent storage. Returns true when storage is (now) persistent.
/// Browsers may grant it silently, prompt, or refuse; any failure is non-fatal.
Future<bool> requestPersistentStorage() async {
  try {
    final html.StorageManager? sm = html.window.navigator.storage;
    if (sm == null) return false;
    if (await sm.persisted()) return true;
    return await sm.persist();
  } catch (_) {
    return false;
  }
}

/// Whether storage is already persistent; null when unsupported.
Future<bool?> isStoragePersisted() async {
  try {
    final html.StorageManager? sm = html.window.navigator.storage;
    if (sm == null) return null;
    return await sm.persisted();
  } catch (_) {
    return null;
  }
}
