import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

/// User-entered zakat inputs (gold/silver gram prices + chosen standard).
@immutable
class ZakatInputs {
  const ZakatInputs({
    required this.goldPricePerGram,
    required this.silverPricePerGram,
    required this.standard,
  });

  final double goldPricePerGram;
  final double silverPricePerGram;
  final ZakatStandard standard;

  ZakatInputs copyWith({
    double? goldPricePerGram,
    double? silverPricePerGram,
    ZakatStandard? standard,
  }) {
    return ZakatInputs(
      goldPricePerGram: goldPricePerGram ?? this.goldPricePerGram,
      silverPricePerGram: silverPricePerGram ?? this.silverPricePerGram,
      standard: standard ?? this.standard,
    );
  }
}

final zakatInputsProvider =
    NotifierProvider<ZakatInputsController, ZakatInputs>(
        ZakatInputsController.new);

class ZakatInputsController extends Notifier<ZakatInputs> {
  static const String _key = 'sb_zakat_inputs';

  @override
  ZakatInputs build() {
    _load();
    return const ZakatInputs(
      goldPricePerGram: 0,
      silverPricePerGram: 0,
      standard: ZakatStandard.gold,
    );
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
        state = ZakatInputs(
          goldPricePerGram: (m['gold'] as num?)?.toDouble() ?? 0,
          silverPricePerGram: (m['silver'] as num?)?.toDouble() ?? 0,
          standard: (m['standard'] == 'silver')
              ? ZakatStandard.silver
              : ZakatStandard.gold,
        );
      }
    } catch (_) {
      // Keep defaults.
    }
  }

  Future<void> update(ZakatInputs next) async {
    state = next;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(<String, dynamic>{
          'gold': next.goldPricePerGram,
          'silver': next.silverPricePerGram,
          'standard': next.standard.name,
        }),
      );
    } catch (_) {
      // Non-fatal.
    }
  }
}

/// The zakat result computed from live data (goals saved, cash surplus,
/// receivables, liabilities) + the user's gram prices.
final zakatResultProvider = Provider<ZakatResult>((ref) {
  final String currency = ref.watch(baseCurrencyProvider);
  final ZakatInputs inputs = ref.watch(zakatInputsProvider);

  final List<Goal> goals =
      ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  var savedMinor = 0;
  for (final Goal g in goals) {
    if (g.saved.currencyCode == currency) savedMinor += g.saved.minorUnits;
  }

  final DebtSummary debts = ref.watch(debtSummaryProvider);
  final FinanceSummary finance = ref.watch(financeSummaryProvider);

  return ZakatCalculator.compute(
    ZakatInput(
      currency: currency,
      standard: inputs.standard,
      goldPricePerGram: inputs.goldPricePerGram,
      silverPricePerGram: inputs.silverPricePerGram,
      savingsMinor: savedMinor,
      surplusMinor: finance.net.minorUnits,
      receivablesMinor: debts.owedToMe.minorUnits,
      liabilitiesMinor: debts.owedByMe.minorUnits,
    ),
  );
});
