import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';

/// Nisab basis chosen by the user (gold or silver standard).
enum ZakatStandard { gold, silver }

/// Immutable inputs to the zakat computation (all money in [currency] minor
/// units; prices are per-gram in the same currency).
@immutable
class ZakatInput {
  const ZakatInput({
    required this.currency,
    required this.standard,
    required this.goldPricePerGram,
    required this.silverPricePerGram,
    required this.savingsMinor, // goals saved
    required this.surplusMinor, // accumulated cash surplus (year net)
    required this.receivablesMinor, // debts owed to me
    required this.liabilitiesMinor, // debts I owe (short term)
    this.portfolioMinor = 0, // funded amount across projects
    this.manualMinor = 0, // user-added wealth (cash / metals / investments)
  });

  final String currency;
  final ZakatStandard standard;
  final double goldPricePerGram;
  final double silverPricePerGram;
  final int savingsMinor;
  final int surplusMinor;
  final int receivablesMinor;
  final int liabilitiesMinor;
  final int portfolioMinor;
  final int manualMinor;
}

/// The zakat result (nisab, zakatable base, obligation, and amount due).
@immutable
class ZakatResult {
  const ZakatResult({
    required this.goldNisab,
    required this.silverNisab,
    required this.adoptedNisab,
    required this.assets,
    required this.liabilities,
    required this.netZakatable,
    required this.obligatory,
    required this.due,
    required this.savings,
    required this.surplus,
    required this.portfolio,
    required this.receivables,
    required this.manual,
  });

  final Money goldNisab;
  final Money silverNisab;
  final Money adoptedNisab;
  final Money assets;
  final Money liabilities;
  final Money netZakatable;
  final bool obligatory;
  final Money due;

  // Asset breakdown (what the gathered assets are made of), for display.
  final Money savings;
  final Money surplus;
  final Money portfolio;
  final Money receivables;
  final Money manual;
}

/// Pure zakat engine — faithful to SmartBudget V1 (Zakat.gs / ZAKAT config):
/// nisab = 85g gold or 595g silver; zakat rate = 2.5% (ربع العشر) on the net
/// zakatable wealth once it reaches nisab.
abstract final class ZakatCalculator {
  static const double goldNisabGrams = 85;
  static const double silverNisabGrams = 595;
  static const double rate = 0.025;

  static ZakatResult compute(ZakatInput i) {
    final Money goldNisab =
        Money.fromDouble(goldNisabGrams * i.goldPricePerGram, i.currency);
    final Money silverNisab =
        Money.fromDouble(silverNisabGrams * i.silverPricePerGram, i.currency);
    final Money adopted =
        i.standard == ZakatStandard.silver ? silverNisab : goldNisab;

    final int assetsMinor = i.savingsMinor +
        i.surplusMinor +
        i.portfolioMinor +
        i.receivablesMinor +
        i.manualMinor;
    final int rawNet = assetsMinor - i.liabilitiesMinor;
    final int netMinor = rawNet < 0 ? 0 : rawNet;

    final bool obligatory =
        adopted.minorUnits > 0 && netMinor >= adopted.minorUnits;
    final int dueMinor = obligatory ? (netMinor * rate).round() : 0;

    return ZakatResult(
      goldNisab: goldNisab,
      silverNisab: silverNisab,
      adoptedNisab: adopted,
      assets: Money(assetsMinor, i.currency),
      liabilities: Money(i.liabilitiesMinor, i.currency),
      netZakatable: Money(netMinor, i.currency),
      obligatory: obligatory,
      due: Money(dueMinor, i.currency),
      savings: Money(i.savingsMinor, i.currency),
      surplus: Money(i.surplusMinor, i.currency),
      portfolio: Money(i.portfolioMinor, i.currency),
      receivables: Money(i.receivablesMinor, i.currency),
      manual: Money(i.manualMinor, i.currency),
    );
  }
}
