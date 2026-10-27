import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart' show newIdbFactoryMemory;

import 'package:smartbudget/core/storage/local_db.dart';
import 'package:smartbudget/core/storage/record_lists.dart';

/// `SB_TEST_LOCAL_DB=1 flutter test` runs every test with the user's lists
/// in the device database (a fresh in-memory one per test) instead of
/// SharedPreferences: the whole app's behaviour, on the new storage.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.environment['SB_TEST_LOCAL_DB'] == '1') {
    setUp(() {
      RecordLists.current = LocalDbRecordLists(newIdbFactoryMemory());
    });
    tearDown(() {
      RecordLists.current = const PrefsRecordLists();
    });
  }
  await testMain();
}
