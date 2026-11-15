import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/metals/application/metals_controller.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_engine.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_market.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_settings.dart';
import 'package:smartbudget/features/zakat/domain/zakat_assembler.dart';

/// Reads and writes [ZakatSettings] for the signed-in account.
///
/// Storage, newest first:
/// - `sb_zakat_settings_<account>`: this format, the only key ever written;
/// - `sb_zakat_inputs_<account>`: the older screen's key, read when the new
///   one doesn't exist yet, and never changed or removed (the older screen
///   keeps working on it).
/// Kept on the device only, like the older key: nothing new is synced.
abstract final class ZakatSettingsStore {
  static const String base = 'sb_zakat_settings';
  static const String legacyBase = 'sb_zakat_inputs';

  /// The settings in [prefs] for [account]; [currency] is the base currency
  /// the older key's amounts were typed in.
  static ZakatSettings read(
      SharedPreferences prefs, String? account, String currency) {
    final String key = AccountKeys.of(base, account);
    final ZakatSettings? current = _decode(prefs.getString(key),
        (Map<String, dynamic> m) => ZakatSettings.fromJson(m));
    if (current != null) return current;
    // The older key, per account; or still device-wide when the older
    // screen hasn't been opened since accounts got their own keys. Only
    // read here: moving it is left to the older screen.
    final String? legacy = prefs.getString(AccountKeys.of(legacyBase, account)) ??
        (account == null ? null : prefs.getString(legacyBase));
    return _decode(legacy,
            (Map<String, dynamic> m) => ZakatSettings.fromLegacy(m, currency)) ??
        ZakatSettings.empty;
  }

  static Future<void> write(
      SharedPreferences prefs, String? account, ZakatSettings s) =>
      prefs.setString(AccountKeys.of(base, account), jsonEncode(s.toJson()));

  static ZakatSettings? _decode(
      String? raw, ZakatSettings Function(Map<String, dynamic>) from) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? j = jsonDecode(raw);
      return j is Map<String, dynamic> ? from(j) : null;
    } catch (_) {
      return null; // unreadable: as if not set
    }
  }
}

final zakatSettingsProvider =
    NotifierProvider<ZakatSettingsController, ZakatSettings>(
        ZakatSettingsController.new);

class ZakatSettingsController extends Notifier<ZakatSettings> {
  String? _account;

  @override
  ZakatSettings build() {
    _account = ref.watch(currentAccountIdProvider);
    _load(_account);
    return ZakatSettings.empty;
  }

  Future<void> _load(String? account) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ZakatSettings s = ZakatSettingsStore.read(
          prefs, account, ref.read(baseCurrencyProvider));
      if (_account != account) return; // another account signed in meanwhile
      state = s;
    } catch (_) {
      // Keep "not set".
    }
  }

  /// Saves [next] under the new key (the older key is left as it is).
  Future<void> update(ZakatSettings next) async {
    state = next;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await ZakatSettingsStore.write(prefs, _account, next);
    } catch (_) {
      // Non-fatal: kept for this session.
    }
  }
}

/// The zakat market (country profile) in use, or null when the user's
/// market has no profile yet: the older calculator stays in use then.
final zakatMarketProvider = Provider<ZakatProfile?>((ref) => ZakatMarkets.resolve(
    ref.watch(zakatSettingsProvider), ref.watch(baseCurrencyProvider)));

/// The engine's input built from the app's data, for today.
final zakatAssemblyProvider = Provider<ZakatAssembly?>((ref) {
  final ZakatProfile? profile = ref.watch(zakatMarketProvider);
  if (profile == null) return null;
  final ZakatSettings settings = ref.watch(zakatSettingsProvider);
  return ZakatAssembler.build(
    profile: profile,
    rules: ZakatMarkets.rulesFor(profile, settings),
    settings: settings,
    zakatDate: AppClock.now(),
    sources: ZakatSources(
      wallets: ref.watch(walletsProvider),
      transactions: ref.watch(transactionsProvider).valueOrNull ?? const [],
      moves: ref.watch(walletMovesProvider).valueOrNull ?? const [],
      goals: ref.watch(goalsProvider).valueOrNull ?? const [],
      projects: ref.watch(projectsProvider).valueOrNull ?? const [],
      debts: ref.watch(debtsProvider).valueOrNull ?? const [],
      metals: ref.watch(metalHoldingsProvider).valueOrNull ?? const [],
      metalPrices: ref.watch(metalPricesProvider),
      ratesVsUsd: ref.watch(ratesProvider),
      ratesAsOf: ref.watch(fxStatusProvider).asOf,
    ),
  );
});

/// The engine's result for today; null outside an enabled market. Not shown
/// on any screen yet (the zakat page still uses the older calculator).
final zakatOutcomeProvider = Provider<ZakatOutcome?>((ref) {
  final ZakatAssembly? a = ref.watch(zakatAssemblyProvider);
  return a == null ? null : ZakatEngine.compute(a.zakatCase);
});
