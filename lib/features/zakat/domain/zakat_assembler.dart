/// Builds the zakat engine's input ([ZakatCase]) from what the app already
/// keeps: wallets and their transactions, goals, metal holdings, debts, the
/// app's exchange rates and metal prices, plus the user's zakat settings.
///
/// Pure (no I/O). Each record enters once under a stable key
/// ("wallet:<id>", "goal:<id>", "metal:<id>", "debt:<id>"), and the rules
/// that keep the same money from being counted twice live here:
/// - a goal's saved money is earmarked inside the wallets unless the user
///   marked it as held outside them (the engine then shows it, uncounted);
/// - a project already moved into a goal (same id) is skipped;
/// - the metals amount typed in the older screen is left out once metal
///   holdings are registered, since it most likely describes the same metal;
/// - wallet balances are taken on the zakat date, so entries dated later
///   (planned or recurring) are not counted.
library;

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_case.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_money.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_settings.dart';

/// The app's data, as the providers hold it.
class ZakatSources {
  const ZakatSources({
    this.wallets = const <Wallet>[],
    this.transactions = const <Transaction>[],
    this.moves = const <WalletMove>[],
    this.goals = const <Goal>[],
    this.projects = const <Project>[],
    this.debts = const <Debt>[],
    this.metals = const <MetalHolding>[],
    this.metalPrices = const <Metal, MetalPrice>{},
    this.ratesVsUsd = const <String, double>{},
    this.ratesAsOf,
  });

  final List<Wallet> wallets;
  final List<Transaction> transactions;
  final List<WalletMove> moves;
  final List<Goal> goals;

  /// Older portfolio projects not yet moved into goals.
  final List<Project> projects;
  final List<Debt> debts;
  final List<MetalHolding> metals;

  /// Price of a gram of the pure metal (the app's market or own price).
  final Map<Metal, MetalPrice> metalPrices;

  /// Units of each currency per 1 US dollar.
  final Map<String, double> ratesVsUsd;
  final DateTime? ratesAsOf;
}

/// Why something the app holds was left out of the case, for the screen to
/// explain.
enum AssemblyNoteCode {
  /// The older screen's metals amount, superseded by registered holdings.
  legacyMetalsSuperseded,

  /// A project with the same id as a goal (already moved into it).
  projectIsGoal,

  /// Wallet entries dated after the zakat date (not counted).
  laterEntriesIgnored,

  /// A debt recorded with a date after the zakat date.
  laterDebtIgnored,
}

class AssemblyNote {
  const AssemblyNote(this.code, {this.ref, this.count});
  final AssemblyNoteCode code;
  final String? ref;
  final int? count;
}

class ZakatAssembly {
  const ZakatAssembly(this.zakatCase, this.notes);
  final ZakatCase zakatCase;
  final List<AssemblyNote> notes;
}

abstract final class ZakatAssembler {
  static const String appRatesSource = 'app-rates';

  static ZakatAssembly build({
    required ZakatProfile profile,
    required ZakatRules rules,
    required ZakatSettings settings,
    required ZakatSources sources,
    required DateTime zakatDate,
  }) {
    final String cur = profile.currency;
    final DateTime day = _day(zakatDate);
    final List<AssemblyNote> notes = <AssemblyNote>[];
    final Map<String, FxQuote> fx = <String, FxQuote>{};

    FxQuote? quote(String from) {
      if (from == cur) return null;
      final FxQuote? have = fx[from];
      if (have != null) return have;
      final FxQuote? q = _appRate(from, cur, sources.ratesVsUsd,
          sources.ratesAsOf ?? day);
      if (q != null) fx[from] = q;
      return q;
    }

    /// [minor] of [from] in the zakat currency, or null without a rate.
    int? inZakatCurrency(int minor, String from) {
      if (from == cur) return minor;
      if (ZakatMoney.decimalsOf(from) == null) return null;
      return quote(from)?.convert(minor, rules.rounding);
    }

    // ---- Wallets: balances on the zakat date ----
    final List<Transaction> txns = <Transaction>[];
    int later = 0;
    for (final Transaction t in sources.transactions) {
      if (_day(t.date).isAfter(day)) {
        later++;
      } else {
        txns.add(t);
      }
    }
    final List<WalletMove> moves = <WalletMove>[];
    for (final WalletMove m in sources.moves) {
      if (_day(m.date).isAfter(day)) {
        later++;
      } else {
        moves.add(m);
      }
    }
    if (later > 0) {
      notes.add(AssemblyNote(AssemblyNoteCode.laterEntriesIgnored, count: later));
    }
    final Map<String, int> balances = WalletMath.balances(
        wallets: sources.wallets, txns: txns, moves: moves);
    final List<ZakatCash> cash = <ZakatCash>[
      for (final Wallet w in sources.wallets)
        ZakatCash(
            key: 'wallet:${w.id}',
            kind: CashKind.wallet,
            currency: w.currency,
            amountMinor: balances[w.id] ?? 0),
    ];
    for (final Wallet w in sources.wallets) {
      quote(w.currency);
    }

    // ---- Goals and older projects ----
    final Set<String> goalIds = <String>{};
    for (final Goal g in sources.goals) {
      goalIds.add(g.id);
      if (g.saved.minorUnits <= 0) continue;
      cash.add(ZakatCash(
          key: 'goal:${g.id}',
          kind: CashKind.goal,
          currency: g.saved.currencyCode,
          amountMinor: g.saved.minorUnits,
          heldOutsideWallets: settings.goalsHeldOutside.contains(g.id)));
      quote(g.saved.currencyCode);
    }
    for (final Project p in sources.projects) {
      if (goalIds.contains(p.id)) {
        notes.add(AssemblyNote(AssemblyNoteCode.projectIsGoal, ref: p.id));
        continue;
      }
      if (p.saved.minorUnits <= 0) continue;
      cash.add(ZakatCash(
          key: 'project:${p.id}',
          kind: CashKind.project,
          currency: p.saved.currencyCode,
          amountMinor: p.saved.minorUnits,
          heldOutsideWallets: settings.goalsHeldOutside.contains(p.id)));
      quote(p.saved.currencyCode);
    }

    // ---- Metals ----
    final List<ZakatMetal> metals = <ZakatMetal>[];
    for (final MetalHolding h in sources.metals) {
      if (h.grams <= 0) continue;
      final MetalUse use = settings.metalUses[h.id] ?? MetalUse.unspecified;
      final int mg = (h.grams * 1000).round();
      switch (h.metal) {
        case Metal.gold:
        case Metal.silver:
          metals.add(ZakatMetal(
              key: 'metal:${h.id}',
              metal: h.metal == Metal.gold
                  ? ZakatMetalKind.gold
                  : ZakatMetalKind.silver,
              grossMilligrams: mg,
              purity: h.purity,
              use: use));
        case Metal.platinum:
        case Metal.palladium:
          {
          // Not gold or silver: zakatable only as trade goods, at market value.
          final MetalPrice? p = sources.metalPrices[h.metal];
          final Money? v = p == null ? null : MetalsValuation.value(h, p);
          if (v != null) quote(v.currencyCode);
          metals.add(ZakatMetal(
              key: 'metal:${h.id}',
              metal: ZakatMetalKind.other,
              grossMilligrams: mg,
              purity: h.purity,
              use: use,
              marketValueMinor: v?.minorUnits,
              currency: v?.currencyCode));
          }
      }
    }
    final bool anyHolding = metals.any((ZakatMetal m) =>
        m.metal == ZakatMetalKind.gold || m.metal == ZakatMetalKind.silver);

    MetalPriceQuote? priceOf(Metal metal, int? own) {
      final String? ownCur = settings.priceCurrency;
      if (own != null && ownCur != null) {
        final int? v = inZakatCurrency(own, ownCur);
        if (v != null && v > 0) {
          return MetalPriceQuote(
              perPureGramMinor: v,
              asOf: settings.pricesAsOf ?? day,
              source: 'user');
        }
      }
      final MetalPrice? p = sources.metalPrices[metal];
      if (p == null || p.perGram <= 0) return null;
      final int? v = inZakatCurrency(
          Money.fromDouble(p.perGram, p.currency).minorUnits, p.currency);
      if (v == null || v <= 0) return null;
      return MetalPriceQuote(
          perPureGramMinor: v, asOf: p.updatedAt ?? day, source: p.source.name);
    }

    // ---- Debts ----
    final List<ZakatReceivable> receivables = <ZakatReceivable>[];
    final List<ZakatDebt> debts = <ZakatDebt>[];
    for (final Debt d in sources.debts) {
      final DateTime? on = d.date;
      if (on != null && _day(on).isAfter(day)) {
        notes.add(AssemblyNote(AssemblyNoteCode.laterDebtIgnored, ref: d.id));
        continue;
      }
      final Money left = DebtCalculator.remaining(d);
      if (left.minorUnits <= 0) continue;
      quote(left.currencyCode);
      if (d.isLent) {
        receivables.add(ZakatReceivable(
            key: 'debt:${d.id}',
            currency: left.currencyCode,
            amountMinor: left.minorUnits,
            collectible: !settings.doubtfulReceivables.contains(d.id)));
      } else {
        debts.add(ZakatDebt(
            key: 'debt:${d.id}',
            currency: left.currencyCode,
            amountMinor: left.minorUnits,
            dueDate: d.dueDate == null ? null : _day(d.dueDate!)));
      }
    }

    // ---- Entered for zakat ----
    final List<ZakatManual> manual = <ZakatManual>[];
    for (final ZakatManual m in settings.manual) {
      if (m.key == 'legacy:metals' && anyHolding) {
        notes.add(const AssemblyNote(AssemblyNoteCode.legacyMetalsSuperseded,
            ref: 'legacy:metals'));
        continue;
      }
      manual.add(m);
      quote(m.currency);
    }
    for (final ZakatInvestment i in settings.investments) {
      quote(i.currency);
    }

    final DateTime? start = settings.hawlStart;
    return ZakatAssembly(
      ZakatCase(
        profile: profile,
        rules: rules,
        zakatDate: day,
        hawlStart: start,
        hawlAdjustDays: settings.hawlAdjustDays,
        cash: cash,
        cashHistory: start == null
            ? null
            : walletHistory(
                wallets: sources.wallets,
                transactions: txns,
                moves: moves,
                from: start,
                to: day,
                value: inZakatCurrency),
        metals: metals,
        goldPrice: priceOf(Metal.gold, settings.goldPerPureGramMinor),
        silverPrice: priceOf(Metal.silver, settings.silverPerPureGramMinor),
        investments: settings.investments,
        receivables: receivables,
        debts: debts,
        manual: manual,
        fx: fx.values.toList(),
      ),
      notes,
    );
  }

  /// Total wallet cash, in the zakat currency, at [from] and after each day
  /// with entries up to [to]. Null when a wallet's currency can't be valued
  /// or [from] is after [to].
  static List<BalancePoint>? walletHistory({
    required List<Wallet> wallets,
    required List<Transaction> transactions,
    required List<WalletMove> moves,
    required DateTime from,
    required DateTime to,
    required int? Function(int minor, String currency) value,
  }) {
    final DateTime start = _day(from);
    final DateTime end = _day(to);
    if (start.isAfter(end)) return null;
    final Map<String, Wallet> byId = <String, Wallet>{
      for (final Wallet w in wallets) w.id: w,
    };
    final Set<String> known = byId.keys.toSet();

    // Balances at the end of the first day.
    final Map<String, int> bal = WalletMath.balances(
      wallets: wallets,
      txns: <Transaction>[
        for (final Transaction t in transactions)
          if (!_day(t.date).isAfter(start)) t,
      ],
      moves: <WalletMove>[
        for (final WalletMove m in moves)
          if (!_day(m.date).isAfter(start)) m,
      ],
    );

    int? total() {
      int sum = 0;
      for (final Wallet w in wallets) {
        final int b = bal[w.id] ?? 0;
        if (b == 0) continue;
        final int? v = value(b, w.currency);
        if (v == null) return null;
        sum += v;
      }
      return sum;
    }

    final int? first = total();
    if (first == null) return null;
    final List<BalancePoint> out = <BalancePoint>[BalancePoint(start, first)];

    void addTo(String id, Money m) {
      final Wallet? w = byId[id];
      if (w == null || m.currencyCode != w.currency) return;
      bal[id] = (bal[id] ?? 0) + m.minorUnits;
    }

    // Later days, in order.
    final Map<DateTime, List<void Function()>> byDay =
        <DateTime, List<void Function()>>{};
    void on(DateTime d, void Function() f) =>
        (byDay[_day(d)] ??= <void Function()>[]).add(f);
    for (final Transaction t in transactions) {
      final DateTime d = _day(t.date);
      if (!d.isAfter(start) || d.isAfter(end)) continue;
      on(d, () {
        final String id = WalletMath.resolve(t.walletId, known);
        addTo(id, t.isIncome
            ? t.amount
            : Money(-t.amount.minorUnits, t.amount.currencyCode));
      });
    }
    for (final WalletMove m in moves) {
      final DateTime d = _day(m.date);
      if (!d.isAfter(start) || d.isAfter(end)) continue;
      on(d, () {
        final String dest = WalletMath.resolve(m.toId, known);
        if (m.kind == MoveKind.transfer) {
          addTo(WalletMath.resolve(m.fromId, known),
              Money(-m.amount.minorUnits, m.amount.currencyCode));
          addTo(dest, m.received);
        } else {
          addTo(dest, m.amount);
        }
      });
    }
    final List<DateTime> days = byDay.keys.toList()..sort();
    for (final DateTime d in days) {
      for (final void Function() f in byDay[d]!) {
        f();
      }
      final int? t = total();
      if (t == null) return null;
      out.add(BalancePoint(d, t));
    }
    return out;
  }

  /// The app's rate from [from] to [to] (both quoted per US dollar) as an
  /// exact decimal quote; null when either rate is missing.
  static FxQuote? _appRate(
      String from, String to, Map<String, double> ratesVsUsd, DateTime asOf) {
    final double? rf = from == 'USD' ? 1 : ratesVsUsd[from];
    final double? rt = to == 'USD' ? 1 : ratesVsUsd[to];
    if (rf == null || rt == null || rf <= 0 || rt <= 0) return null;
    final double r = rt / rf;
    if (!r.isFinite || r <= 0) return null;
    return FxQuote.parse(
        from: from,
        to: to,
        rate: r.toStringAsFixed(8),
        asOf: asOf,
        source: appRatesSource);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
