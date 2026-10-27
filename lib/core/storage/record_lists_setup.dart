import 'package:idb_shim/idb.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/storage/local_db.dart';
import 'package:smartbudget/core/storage/local_db_factory.dart';
import 'package:smartbudget/core/storage/record_lists.dart';

/// Picks where the user's lists are kept, before anything reads them.
///
/// With the device database on ([AppEnv.indexedDb]: IndexedDB on the web, a
/// database file on Android) it is used. With it off, whatever it held is
/// first copied back to SharedPreferences; if that can't be done, the
/// database stays in use rather than showing an older copy.
Future<void> chooseRecordLists({
  bool enabled = AppEnv.indexedDb,
  IdbFactory? factory,
}) async {
  final IdbFactory? f = factory ?? await deviceIdbFactory();
  if (f == null) return; // tests, desktop
  bool back = false;
  if (!enabled) {
    try {
      back = await LocalDbRecordLists.restoreToPrefs(f)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      back = false;
    }
  }
  RecordLists.current =
      enabled || !back ? LocalDbRecordLists(f) : const PrefsRecordLists();
}
