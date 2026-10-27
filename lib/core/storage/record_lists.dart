import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/stored_list.dart';

/// Where the user's lists of records (transactions, budgets, goals, wallets...)
/// are kept on the device, each under its own key (`sb_txns_<account>`...).
///
/// [PrefsRecordLists] is how it has always been: one JSON text per list in
/// SharedPreferences (the browser's localStorage on the web). The device
/// database ([LocalDbRecordLists], behind `INDEXED_DB`) keeps each record on
/// its own instead. Stores only call [load] and [save], so which one is used
/// changes nothing else.
abstract interface class RecordLists {
  /// The one in use (chosen at start-up, see main.dart).
  static RecordLists current = const PrefsRecordLists();

  /// The records of [key]. A record that can't be read is left out on its own
  /// and kept aside, never the whole list.
  Future<List<T>> load<T>(
      String key, T Function(Map<String, dynamic>) fromJson);

  /// Stores exactly [records] under [key]; throws when it couldn't.
  Future<void> save(String key, List<Map<String, dynamic>> records);

  /// Forgets every list for which [which] is true (an account removed from
  /// this device).
  Future<void> forget(bool Function(String key) which);

  /// Moves the list [from] to [to] when [to] has none yet.
  Future<void> move(String from, String to);
}

/// The lists as JSON texts in SharedPreferences.
class PrefsRecordLists implements RecordLists {
  const PrefsRecordLists();

  @override
  Future<List<T>> load<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String? raw = p.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    return StoredList.read(p, key, raw, fromJson);
  }

  @override
  Future<void> save(String key, List<Map<String, dynamic>> records) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    if (!await p.setString(key, jsonEncode(records))) {
      throw StateError('not stored');
    }
  }

  // SharedPreferences keys are removed and moved by their owners
  // (AccountDeletion.wipeLocal, adoptDeviceData).
  @override
  Future<void> forget(bool Function(String key) which) async {}

  @override
  Future<void> move(String from, String to) async {}
}
