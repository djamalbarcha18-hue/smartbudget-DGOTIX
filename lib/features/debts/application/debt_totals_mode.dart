import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the debts page adds its totals up when debts are in more than one
/// currency. Only that page follows it: the dashboard, zakat, the health
/// score and the reports need one number, so they always convert.
enum DebtTotalsMode {
  /// One total in the base currency, other currencies at today's rate.
  converted,

  /// One line per currency, nothing converted: each total stays exactly what
  /// was lent or borrowed, whatever the rates do.
  perCurrency,
}

final debtTotalsModeProvider =
    NotifierProvider<DebtTotalsModeController, DebtTotalsMode>(
        DebtTotalsModeController.new);

/// The user's choice, kept on the device.
class DebtTotalsModeController extends Notifier<DebtTotalsMode> {
  static const String key = 'sb_debt_totals_mode';

  @override
  DebtTotalsMode build() {
    _load();
    return DebtTotalsMode.converted;
  }

  Future<void> _load() async {
    try {
      final String? v = (await SharedPreferences.getInstance()).getString(key);
      if (v == DebtTotalsMode.perCurrency.name) {
        state = DebtTotalsMode.perCurrency;
      }
    } catch (_) {
      // Keep the default (also when the container ended before the read).
    }
  }

  Future<void> set(DebtTotalsMode mode) async {
    state = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(key, mode.name);
    } catch (_) {}
  }
}
