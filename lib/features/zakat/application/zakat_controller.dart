import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/application/portfolio_controller.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/features/zakat/domain/hawl.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

/// User-entered zakat inputs (gold/silver gram prices, chosen standard, and the
/// Gregorian date the wealth first reached nisab — the hawl start).
@immutable
class ZakatInputs {
  const ZakatInputs({
    required this.goldPricePerGram,
    required this.silverPricePerGram,
    required this.standard,
    this.hawlStart,
    this.cash = 0,
    this.metals = 0,
    this.investments = 0,
  });

  final double goldPricePerGram;
  final double silverPricePerGram;
  final ZakatStandard standard;
  final DateTime? hawlStart;

  /// Manual zakatable wealth the app doesn't track (in base currency).
  final double cash;
  final double metals; // value of gold/silver holdings
  final double investments; // other liquid investments

  ZakatInputs copyWith({
    double? goldPricePerGram,
    double? silverPricePerGram,
    ZakatStandard? standard,
    double? cash,
    double? metals,
    double? investments,
  }) {
    return ZakatInputs(
      goldPricePerGram: goldPricePerGram ?? this.goldPricePerGram,
      silverPricePerGram: silverPricePerGram ?? this.silverPricePerGram,
      standard: standard ?? this.standard,
      hawlStart: hawlStart,
      cash: cash ?? this.cash,
      metals: metals ?? this.metals,
      investments: investments ?? this.investments,
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
          hawlStart: DateTime.tryParse('${m['hawlStart']}'),
          cash: (m['cash'] as num?)?.toDouble() ?? 0,
          metals: (m['metals'] as num?)?.toDouble() ?? 0,
          investments: (m['investments'] as num?)?.toDouble() ?? 0,
        );
      }
    } catch (_) {
      // Keep defaults.
    }
  }

  Future<void> update(ZakatInputs next) async {
    state = next;
    await _persist();
  }

  /// Sets or clears (null) the hawl start date.
  Future<void> setHawlStart(DateTime? date) async {
    state = ZakatInputs(
      goldPricePerGram: state.goldPricePerGram,
      silverPricePerGram: state.silverPricePerGram,
      standard: state.standard,
      hawlStart: date,
      cash: state.cash,
      metals: state.metals,
      investments: state.investments,
    );
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(<String, dynamic>{
          'gold': state.goldPricePerGram,
          'silver': state.silverPricePerGram,
          'standard': state.standard.name,
          'hawlStart': state.hawlStart?.toIso8601String(),
          'cash': state.cash,
          'metals': state.metals,
          'investments': state.investments,
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

  // Portfolio: funded (saved) amount across projects in the base currency.
  final List<Project> projects =
      ref.watch(projectsProvider).valueOrNull ?? const <Project>[];
  var portfolioMinor = 0;
  for (final Project p in projects) {
    if (p.saved.currencyCode == currency) portfolioMinor += p.saved.minorUnits;
  }

  final DebtSummary debts = ref.watch(debtSummaryProvider);
  final FinanceSummary finance = ref.watch(financeSummaryProvider);

  // Manual wealth the app doesn't track (base currency).
  final int manualMinor =
      Money.fromDouble(inputs.cash + inputs.metals + inputs.investments, currency)
          .minorUnits;

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
      portfolioMinor: portfolioMinor,
      manualMinor: manualMinor,
    ),
  );
});

/// The hawl (lunar-year) status, or null when no start date is set yet.
final zakatHawlProvider = Provider<HawlStatus?>((ref) {
  final DateTime? start = ref.watch(zakatInputsProvider).hawlStart;
  if (start == null) return null;
  return HawlStatus.compute(start, DateTime.now());
});
