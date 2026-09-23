/// Non-web stub: there is no browser storage to protect.
Future<bool> requestPersistentStorage() async => false;

/// Whether storage is already persistent; null when unknown/unsupported.
Future<bool?> isStoragePersisted() async => null;
