/// Whether everything the device holds was read back.
///
/// A list or a record that couldn't be read is left out (and kept aside), so
/// the app keeps working. But to cloud sync a record that is missing looks
/// deleted, and a deletion is sent to every other device. While anything was
/// left out, sync doesn't send deletions it can't be sure of: the cloud copy
/// of those records comes back instead (see SyncGuard).
abstract final class ReadHealth {
  static final Set<String> _lost = <String>{};

  /// Something under [key] couldn't be read this session.
  static void lost(String key) => _lost.add(key);

  /// True when anything couldn't be read since the app started.
  static bool get lostSomething => _lost.isNotEmpty;

  /// For tests.
  static void reset() => _lost.clear();
}
