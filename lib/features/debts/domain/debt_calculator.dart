import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/exchange_rates/domain/exchange_rate_calculator.dart';

/// Debts position summary (mirrors V1 debtSummary: amounts still outstanding).
@immutable
class DebtSummary {
  const DebtSummary({
    required this.owedToMe,
    required this.owedByMe,
    required this.net,
    required this.openCount,
    this.convertedCount = 0,
    this.missingRateCodes = const <String>[],
  });

  final Money owedToMe; // remaining on unpaid "lent"
  final Money owedByMe; // remaining on unpaid "borrowed"
  final Money net; // owedToMe - owedByMe
  final int openCount;

  /// Open debts in another currency that are in the totals at today's
  /// exchange rate (so the totals are approximate when this is above zero).
  final int convertedCount;

  /// Currencies of open debts that have no exchange rate yet: those debts are
  /// left out of the totals, and the page says so instead of hiding them.
  final List<String> missingRateCodes;
}

/// What is owed in one currency, not converted into any other.
@immutable
class CurrencyPosition {
  const CurrencyPosition({
    required this.code,
    required this.owedToMe,
    required this.owedByMe,
    required this.openCount,
  });

  final String code;
  final Money owedToMe;
  final Money owedByMe;
  final int openCount;

  Money get net => Money(owedToMe.minorUnits - owedByMe.minorUnits, code);
}

/// Pure debt calculations. `remaining` and `status` are derived here so they are
/// consistent everywhere and unit-tested.
abstract final class DebtCalculator {
  /// Remaining = max(0, original - paid) — same as V1.
  static Money remaining(Debt d) {
    final int r = d.original.minorUnits - d.paid.minorUnits;
    return Money(r < 0 ? 0 : r, d.original.currencyCode);
  }

  /// Status derivation (per the SaaS spec's four states):
  ///   paid            → remaining == 0
  ///   overdue         → past due date and still owed
  ///   partiallyPaid   → some paid but still owed (not overdue)
  ///   active          → nothing paid yet (not overdue)
  static DebtStatus status(Debt d, {DateTime? now}) {
    final Money r = remaining(d);
    if (r.isZero) return DebtStatus.paid;
    final DateTime today = now ?? AppClock.now();
    if (d.dueDate != null && d.dueDate!.isBefore(_dateOnly(today))) {
      return DebtStatus.overdue;
    }
    return d.paid.minorUnits > 0 ? DebtStatus.partiallyPaid : DebtStatus.active;
  }

  /// [amount] in [base] at the given rates (units of each currency per 1 USD),
  /// or null when either currency has no rate.
  static Money? inBase(
      Money amount, String base, Map<String, double> ratesVsUsd) {
    if (amount.currencyCode == base) return amount;
    final double from = ratesVsUsd[amount.currencyCode] ?? 0;
    final double to = ratesVsUsd[base] ?? 0;
    if (from <= 0 || to <= 0) return null;
    return Money.fromDouble(
      ExchangeRateCalculator.convert(
        amount: amount.asDouble,
        from: amount.currencyCode,
        to: base,
        ratesVsUsd: ratesVsUsd,
      ),
      base,
    );
  }

  /// The position in [baseCurrency]. A debt in another currency is counted at
  /// today's rate ([ratesVsUsd]); one whose currency has no rate yet is left
  /// out and its currency listed in [DebtSummary.missingRateCodes], never
  /// dropped silently.
  static DebtSummary summary(
    List<Debt> debts,
    String baseCurrency, {
    Map<String, double> ratesVsUsd = const <String, double>{},
  }) {
    var toMe = 0;
    var byMe = 0;
    var open = 0;
    var converted = 0;
    final Set<String> missing = <String>{};
    for (final Debt d in debts) {
      final Money r = remaining(d);
      if (r.isZero) continue; // fully settled
      open++;
      final Money? inBase0 = inBase(r, baseCurrency, ratesVsUsd);
      if (inBase0 == null) {
        missing.add(d.original.currencyCode);
        continue;
      }
      if (d.original.currencyCode != baseCurrency) converted++;
      if (d.isLent) {
        toMe += inBase0.minorUnits;
      } else {
        byMe += inBase0.minorUnits;
      }
    }
    return DebtSummary(
      owedToMe: Money(toMe, baseCurrency),
      owedByMe: Money(byMe, baseCurrency),
      net: Money(toMe - byMe, baseCurrency),
      openCount: open,
      convertedCount: converted,
      missingRateCodes: (missing.toList()..sort()),
    );
  }

  /// What is still owed, one line per currency and nothing converted: the
  /// base currency first, then the others by code. A currency with no open
  /// debt has no line.
  static List<CurrencyPosition> byCurrency(
      List<Debt> debts, String baseCurrency) {
    final Map<String, int> toMe = <String, int>{};
    final Map<String, int> byMe = <String, int>{};
    final Map<String, int> open = <String, int>{};
    for (final Debt d in debts) {
      final Money r = remaining(d);
      if (r.isZero) continue;
      final String code = d.original.currencyCode;
      open[code] = (open[code] ?? 0) + 1;
      final Map<String, int> side = d.isLent ? toMe : byMe;
      side[code] = (side[code] ?? 0) + r.minorUnits;
    }
    final List<String> codes = open.keys.toList()
      ..sort((String a, String b) {
        if (a == baseCurrency) return -1;
        if (b == baseCurrency) return 1;
        return a.compareTo(b);
      });
    return <CurrencyPosition>[
      for (final String code in codes)
        CurrencyPosition(
          code: code,
          owedToMe: Money(toMe[code] ?? 0, code),
          owedByMe: Money(byMe[code] ?? 0, code),
          openCount: open[code]!,
        ),
    ];
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
