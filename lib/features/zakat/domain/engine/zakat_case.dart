/// What the zakat engine is given: every asset and debt with a stable key
/// (where it came from in the app), its own currency, and its minor units.
/// Built by the app from wallets, metals, debts and the user's own entries;
/// the engine never reads storage itself.
library;

import 'package:smartbudget/features/zakat/domain/engine/zakat_money.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';

enum CashKind {
  /// A wallet's balance on the zakat date.
  wallet,

  /// Money saved for a goal (only counted when held outside the wallets).
  goal,

  /// An older portfolio project's saved money (same rule as goals).
  project,

  /// Cash the app doesn't track (at home, another bank), entered by hand.
  manual,
}

class ZakatCash {
  const ZakatCash({
    required this.key,
    required this.kind,
    required this.currency,
    required this.amountMinor,
    this.heldOutsideWallets = false,
  });

  /// Unique and stable: "wallet:general", "goal:g1", "manual:cash".
  final String key;
  final CashKind kind;
  final String currency;
  final int amountMinor;

  /// For a goal or project: its money is kept outside the app's wallets, so
  /// it isn't already in a wallet balance.
  final bool heldOutsideWallets;
}

/// Total wallet cash (zakat currency) from a moment on, for the policies
/// that look at the balance during the hawl.
class BalancePoint {
  const BalancePoint(this.at, this.totalMinor);
  final DateTime at;
  final int totalMinor;
}

enum ZakatMetalKind { gold, silver, other }

enum MetalUse { adornment, savings, trade, unspecified }

class ZakatMetal {
  const ZakatMetal({
    required this.key,
    required this.metal,
    required this.grossMilligrams,
    required this.purity,
    required this.use,
    this.marketValueMinor,
    this.currency,
  });

  final String key;
  final ZakatMetalKind metal;

  /// As weighed, alloy included, in milligrams.
  final int grossMilligrams;

  /// Karats (out of 24) for gold, parts per thousand for silver.
  final int purity;
  final MetalUse use;

  /// For a metal other than gold or silver held for trade: its market value
  /// (in [currency]); such a metal is otherwise not zakatable.
  final int? marketValueMinor;
  final String? currency;
}

/// A price per gram of the pure metal, in the zakat currency.
class MetalPriceQuote {
  const MetalPriceQuote({
    required this.perPureGramMinor,
    required this.asOf,
    required this.source,
  });
  final int perPureGramMinor;
  final DateTime asOf;
  final String source;
}

enum InvestmentKind {
  tradingShares,
  retainedShares,
  tradeGoods,
  rentalProperty,
  unspecified,
}

class ZakatInvestment {
  const ZakatInvestment({
    required this.key,
    required this.kind,
    required this.currency,
    required this.marketValueMinor,
    this.zakatablePartMinor,
  });

  final String key;
  final InvestmentKind kind;
  final String currency;
  final int marketValueMinor;

  /// For retained shares: the part that is zakatable (the company's
  /// zakatable assets per share times the shares held), when known.
  final int? zakatablePartMinor;
}

class ZakatReceivable {
  const ZakatReceivable({
    required this.key,
    required this.currency,
    required this.amountMinor,
    this.collectible = true,
  });
  final String key;
  final String currency;
  final int amountMinor;

  /// False when repayment is doubtful.
  final bool collectible;
}

class ZakatDebt {
  const ZakatDebt({
    required this.key,
    required this.currency,
    required this.amountMinor,
    this.dueDate,
  });
  final String key;
  final String currency;

  /// What is still owed.
  final int amountMinor;

  /// Null: no term, payable now.
  final DateTime? dueDate;
}

enum ManualKind { cash, metal, other }

class ZakatManual {
  const ZakatManual({
    required this.key,
    required this.kind,
    required this.currency,
    required this.amountMinor,
  });
  final String key;
  final ManualKind kind;
  final String currency;
  final int amountMinor;
}

class ZakatCase {
  const ZakatCase({
    required this.profile,
    required this.rules,
    required this.zakatDate,
    this.hawlStart,
    this.hawlAdjustDays = 0,
    this.cash = const <ZakatCash>[],
    this.cashHistory,
    this.metals = const <ZakatMetal>[],
    this.goldPrice,
    this.silverPrice,
    this.investments = const <ZakatInvestment>[],
    this.receivables = const <ZakatReceivable>[],
    this.debts = const <ZakatDebt>[],
    this.manual = const <ZakatManual>[],
    this.fx = const <FxQuote>[],
  });

  final ZakatProfile profile;
  final ZakatRules rules;

  /// The day the calculation is for (the end of the hawl, or an estimate).
  final DateTime zakatDate;

  /// The day the wealth reached nisab; null when not set yet.
  final DateTime? hawlStart;
  final int hawlAdjustDays;

  final List<ZakatCash> cash;

  /// Total wallet cash over the hawl, oldest first; null when unknown.
  final List<BalancePoint>? cashHistory;

  final List<ZakatMetal> metals;
  final MetalPriceQuote? goldPrice;
  final MetalPriceQuote? silverPrice;
  final List<ZakatInvestment> investments;
  final List<ZakatReceivable> receivables;
  final List<ZakatDebt> debts;
  final List<ZakatManual> manual;

  /// Rates into the zakat currency, dated and sourced.
  final List<FxQuote> fx;
}
