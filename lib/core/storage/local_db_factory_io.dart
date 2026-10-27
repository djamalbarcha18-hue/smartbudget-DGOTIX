import 'dart:io';

import 'package:idb_shim/idb_io.dart';
import 'package:path_provider/path_provider.dart';

/// On Android, a database file in the app's support folder (not its cache):
/// the same records, kept by the same code as in the browser.
Future<IdbFactory?> deviceIdbFactory() async {
  if (!Platform.isAndroid) return null;
  try {
    final Directory dir = await getApplicationSupportDirectory();
    return getIdbFactorySembastIo('${dir.path}${Platform.pathSeparator}db');
  } catch (_) {
    return null;
  }
}
