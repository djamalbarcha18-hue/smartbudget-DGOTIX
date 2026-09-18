import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';

/// Debts position summary (mirrors V1 debtSummary: amounts still outstanding).
@immutable
class DebtSummary {
  const DebtSummary({
    required this.owedToMe,
    required this.owedByMe,
    required this.net,
    required this.openCount,
  });

  final Money owedToMe; // remaining on unpaid "lent"
  final Money owedByMe; // remaining on unpaid "borrowed"
  final Money net; // owedToMe - owedByMe
  final int openCount;
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
    final DateTime today = now ?? DateTime.now();
    if (d.dueDate != null && d.dueDate!.isBefore(_dateOnly(today))) {
      return DebtStatus.overdue;
    }
    return d.paid.minorUnits > 0 ? DebtStatus.partiallyPaid : DebtStatus.active;
  }

  static DebtSummary summary(List<Debt> debts, String baseCurrency) {
    var toMe = 0;
    var byMe = 0;
    var open = 0;
    for (final Debt d in debts) {
      if (d.original.currencyCode != baseCurrency) continue;
      final Money r = remaining(d);
      if (r.isZero) continue; // fully settled
      open++;
      if (d.isLent) {
        toMe += r.minorUnits;
      } else {
        byMe += r.minorUnits;
      }
    }
    return DebtSummary(
      owedToMe: Money(toMe, baseCurrency),
      owedByMe: Money(byMe, baseCurrency),
      net: Money(toMe - byMe, baseCurrency),
      openCount: open,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
