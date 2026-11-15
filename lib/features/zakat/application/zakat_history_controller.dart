import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';
import 'package:smartbudget/features/zakat/application/zakat_engine_providers.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_engine.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_record.dart';
import 'package:smartbudget/features/zakat/domain/zakat_assembler.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

/// The confirmed zakat calculations of an account, on the device
/// (`sb_zakat_history_<account>`). Not synced; carried by the exported
/// backup file (see ZakatBackupIo).
abstract final class ZakatHistoryStore {
  static const String base = 'sb_zakat_history';

  static List<Object?> readRaw(SharedPreferences prefs, String? account) {
    final String? raw = prefs.getString(AccountKeys.of(base, account));
    if (raw == null || raw.isEmpty) return const <Object?>[];
    try {
      final Object? j = jsonDecode(raw);
      return j is List ? List<Object?>.of(j) : const <Object?>[];
    } catch (_) {
      return const <Object?>[];
    }
  }

  static Future<void> writeRaw(
          SharedPreferences prefs, String? account, List<Object?> raw) =>
      prefs.setString(AccountKeys.of(base, account), jsonEncode(raw));
}

final zakatHistoryProvider =
    NotifierProvider<ZakatHistoryController, List<ZakatRecord>>(
        ZakatHistoryController.new);

class ZakatHistoryController extends Notifier<List<ZakatRecord>> {
  String? _account;

  @override
  List<ZakatRecord> build() {
    _account = ref.watch(currentAccountIdProvider);
    _load(_account);
    return const <ZakatRecord>[];
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Object?> raw = ZakatHistoryStore.readRaw(prefs, account);
      if (_account != account) return;
      state = ZakatHistory.read(raw);
    } catch (_) {
      // Keep the empty list.
    }
  }

  /// Saves today's calculation as a record; null (nothing saved) outside an
  /// enabled market or when the result is incomplete.
  Future<ZakatRecord?> confirm({String? note}) async {
    final ZakatAssembly? a = ref.read(zakatAssemblyProvider);
    final ZakatOutcome? o = ref.read(zakatOutcomeProvider);
    if (a == null || o == null) return null;
    final DateTime now = AppClock.now();
    final ZakatRecord? r = ZakatRecord.fromOutcome(o, a.zakatCase,
        id: 'zk-${now.microsecondsSinceEpoch}', savedAt: now, note: note);
    if (r == null) return null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Object?> raw = ZakatHistoryStore.readRaw(prefs, _account);
    final List<Object?> next = ZakatHistory.append(raw, r);
    await ZakatHistoryStore.writeRaw(prefs, _account, next);
    state = ZakatHistory.read(next);
    return r;
  }
}

/// What the dashboard and the assistant show: whether zakat is due now and
/// how much.
class ZakatDue {
  const ZakatDue({
    required this.obligatory,
    required this.due,
    this.fromEngine = false,
  });

  final bool obligatory;
  final Money due;

  /// From the country engine (else the older calculator).
  final bool fromEngine;

  /// The engine's answer when it applies ([outcome] not null), else the
  /// older calculator's.
  static ZakatDue from(ZakatOutcome? outcome, ZakatResult Function() legacy) {
    if (outcome != null) {
      return ZakatDue(
        obligatory: outcome.obligatoryNow && outcome.dueMinor > 0,
        due: Money(outcome.dueMinor, outcome.currency),
        fromEngine: true,
      );
    }
    final ZakatResult r = legacy();
    return ZakatDue(obligatory: r.obligatory, due: r.due);
  }
}

final zakatDueProvider = Provider<ZakatDue>((ref) => ZakatDue.from(
    ref.watch(zakatOutcomeProvider), () => ref.watch(zakatResultProvider)));
