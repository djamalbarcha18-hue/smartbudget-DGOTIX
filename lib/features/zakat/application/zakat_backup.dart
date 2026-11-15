import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/features/zakat/application/zakat_engine_providers.dart';
import 'package:smartbudget/features/zakat/application/zakat_history_controller.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_record.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_settings.dart';

/// The zakat part of an exported backup FILE (key "zakat"): the settings
/// and the confirmed history. Only the file carries it; cloud sync is not
/// changed and never sees it.
abstract final class ZakatBackupIo {
  static const String section = 'zakat';

  /// The section to add to a file, or null when there is nothing to carry.
  static Map<String, dynamic>? export(
      SharedPreferences prefs, String? account, String currency) {
    final ZakatSettings s = ZakatSettingsStore.read(prefs, account, currency);
    final List<Object?> history = ZakatHistoryStore.readRaw(prefs, account);
    final bool hasSettings = jsonEncode(s.toJson()) !=
        jsonEncode(ZakatSettings.empty.toJson());
    if (!hasSettings && history.isEmpty) return null;
    return <String, dynamic>{
      'v': 1,
      if (hasSettings) 'settings': s.toJson(),
      if (history.isNotEmpty) 'history': history,
    };
  }

  /// Restores the section of [file] (a decoded backup file), never
  /// destructively: records are added by id (none changed or removed), and
  /// the settings are written only when the device has none at all (neither
  /// the new nor the older key). Returns how many records were added.
  static Future<int> import(SharedPreferences prefs, String? account,
      Map<String, dynamic> file) async {
    final Object? z = file[section];
    if (z is! Map) return 0;
    final Map<String, dynamic> zakat = z.cast<String, dynamic>();

    int added = 0;
    final Object? incoming = zakat['history'];
    if (incoming is List) {
      final List<Object?> local = ZakatHistoryStore.readRaw(prefs, account);
      final List<Object?> merged =
          ZakatHistory.merge(local, List<Object?>.of(incoming));
      added = merged.length - local.length;
      if (added > 0) await ZakatHistoryStore.writeRaw(prefs, account, merged);
    }

    final Object? settings = zakat['settings'];
    final bool deviceHasSettings =
        prefs.containsKey(AccountKeys.of(ZakatSettingsStore.base, account)) ||
            prefs.containsKey(
                AccountKeys.of(ZakatSettingsStore.legacyBase, account)) ||
            (account != null &&
                prefs.containsKey(ZakatSettingsStore.legacyBase));
    if (settings is Map && !deviceHasSettings) {
      await ZakatSettingsStore.write(prefs, account,
          ZakatSettings.fromJson(settings.cast<String, dynamic>()));
    }
    return added;
  }
}
