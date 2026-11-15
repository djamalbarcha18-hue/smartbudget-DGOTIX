/// The core zakat engine: a pure function from a [ZakatCase] to a
/// [ZakatOutcome]. No storage, no UI, no country values (those come in the
/// case's profile), no floating point.
///
/// The zakatable base is what the user holds on the zakat date: wallet
/// balances, gold and silver, investments by their nature, receivables, and
/// cash kept elsewhere, less the debts the rules deduct. Each asset has one
/// key, so nothing is counted twice; anything that can't be valued exactly
/// (a missing rate or price) stops the result instead of being dropped.
library;

import 'package:smartbudget/features/zakat/domain/engine/zakat_case.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_hawl.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_money.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

enum ZakatStatus {
  /// Something needed is missing (a rate, a price, the nisab): no amount.
  incomplete,

  /// An amount, but not a final one (estimate, unapproved rules, assumptions).
  provisional,

  /// Everything known and the rules approved.
  final_,
}

enum ZakatIssueCode {
  // Blocking: no amount can be given.
  unknownCurrency,
  missingRate,
  missingGoldPrice,
  missingSilverPrice,
  missingOfficialNisab,

  // Cautions: the amount is provisional.
  rulesNotApproved,
  hawlStartMissing,
  beforeHawlEnd,
  historyMissing,
  officialNisabStale,
  metalUseUnspecified,
  manualMetalMayDuplicate,
  retainedSharesFullValue,
  investmentKindUnspecified,
  duplicateSource,
  nisabNotMetAtHawlStart,
  droppedBelowNisab,
}

class ZakatIssue {
  const ZakatIssue(this.code, {this.ref, this.at});
  final ZakatIssueCode code;

  /// The source key or currency it is about.
  final String? ref;
  final DateTime? at;

  bool get blocking => code.index <= ZakatIssueCode.missingOfficialNisab.index;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code.name,
        if (ref != null) 'ref': ref,
        if (at != null) 'at': at!.toIso8601String(),
      };
}

enum ZakatSection { cash, metal, investment, receivable, manual, debt }

/// Why a line counts as it does.
enum LineNote {
  counted,
  insideWallets,
  acquiredDuringHawl,
  adornmentExempt,
  notZakatableMetal,
  zakatablePart,
  fullValueFallback,
  rentalPropertyExcluded,
  doubtfulReceivable,
  untilReceived,
  notDeducted,
  duplicate,
  unvalued,
}

class ZakatLine {
  const ZakatLine({
    required this.key,
    required this.section,
    required this.currency,
    required this.originalMinor,
    required this.valueMinor,
    required this.counted,
    required this.note,
  });

  final String key;
  final ZakatSection section;

  /// The amount as recorded, in its own currency.
  final String currency;
  final int originalMinor;

  /// What it counts for, in the zakat currency (0 when not counted).
  final int valueMinor;
  final bool counted;
  final LineNote note;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'section': section.name,
        'currency': currency,
        'original': originalMinor,
        'value': valueMinor,
        'counted': counted,
        'note': note.name,
      };
}

class ZakatNisab {
  const ZakatNisab({
    required this.basis,
    required this.amountMinor,
    required this.source,
    this.asOf,
    this.hijriYear,
    this.grams,
    this.karat,
    this.gramPriceMinor,
  });

  final NisabBasis basis;
  final int amountMinor;
  final String source;
  final DateTime? asOf;
  final int? hijriYear;
  final int? grams;
  final int? karat;
  final int? gramPriceMinor;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'basis': basis.name,
        'amount': amountMinor,
        'source': source,
        if (asOf != null) 'asOf': asOf!.toIso8601String(),
        if (hijriYear != null) 'hijriYear': hijriYear,
        if (grams != null) 'grams': grams,
        if (karat != null) 'karat': karat,
        if (gramPriceMinor != null) 'gramPrice': gramPriceMinor,
      };
}

class ZakatOutcome {
  const ZakatOutcome({
    required this.status,
    required this.currency,
    required this.zakatDate,
    required this.rules,
    required this.issues,
    required this.lines,
    required this.assetsMinor,
    required this.deductionsMinor,
    required this.baseMinor,
    required this.nisab,
    required this.hawl,
    required this.nisabMet,
    required this.obligatoryNow,
    required this.dueMinor,
    required this.fxUsed,
  });

  final ZakatStatus status;
  final String currency;
  final DateTime zakatDate;
  final ZakatRules rules;
  final List<ZakatIssue> issues;
  final List<ZakatLine> lines;
  final int assetsMinor;
  final int deductionsMinor;

  /// Assets less deductions, never below zero.
  final int baseMinor;
  final ZakatNisab? nisab;
  final ZakatHawl? hawl;

  /// The base reached the nisab (and kept it as the rules require).
  final bool nisabMet;

  /// [nisabMet] and the hawl is complete on the zakat date.
  final bool obligatoryNow;

  /// 2.5% of the base when [nisabMet] (also before the hawl ends, as an
  /// estimate); 0 otherwise.
  final int dueMinor;
  final List<FxQuote> fxUsed;

  bool has(ZakatIssueCode c) => issues.any((ZakatIssue i) => i.code == c);
}

abstract final class ZakatEngine {
  static const int goldNisabGrams = 85;
  static const int silverNisabGrams = 595;

  static ZakatOutcome compute(ZakatCase c) {
    final String cur = c.profile.currency;
    final ZakatRules rules = c.rules;
    final List<ZakatIssue> issues = <ZakatIssue>[];
    final List<ZakatLine> lines = <ZakatLine>[];
    final Set<String> seen = <String>{};
    final Map<String, FxQuote> usedFx = <String, FxQuote>{};
    final DateTime d = DateTime(c.zakatDate.year, c.zakatDate.month, c.zakatDate.day);

    void issue(ZakatIssueCode code, {String? ref, DateTime? at}) {
      if (issues.any((ZakatIssue i) => i.code == code && i.ref == ref)) return;
      issues.add(ZakatIssue(code, ref: ref, at: at));
    }

    /// [minor] of [from] in the zakat currency; null (and a blocking issue)
    /// when it can't be valued exactly.
    int? toBase(int minor, String from) {
      if (ZakatMoney.decimalsOf(from) == null) {
        issue(ZakatIssueCode.unknownCurrency, ref: from);
        return null;
      }
      if (from == cur) return minor;
      FxQuote? q;
      for (final FxQuote f in c.fx) {
        if (f.from == from && f.to == cur) q = f;
      }
      if (q == null) {
        issue(ZakatIssueCode.missingRate, ref: from);
        return null;
      }
      usedFx[from] = q;
      return q.convert(minor, rules.rounding);
    }

    bool fresh(String key) {
      if (seen.add(key)) return true;
      issue(ZakatIssueCode.duplicateSource, ref: key);
      return false;
    }

    void add(String key, ZakatSection s, String currency, int original,
        LineNote note,
        {int? value}) {
      final bool counted = note == LineNote.counted ||
          note == LineNote.zakatablePart ||
          note == LineNote.fullValueFallback;
      int v = 0;
      if (counted) {
        final int? b = value ?? toBase(original, currency);
        if (b == null) {
          lines.add(ZakatLine(
              key: key,
              section: s,
              currency: currency,
              originalMinor: original,
              valueMinor: 0,
              counted: false,
              note: LineNote.unvalued));
          return;
        }
        v = b;
      }
      lines.add(ZakatLine(
          key: key,
          section: s,
          currency: currency,
          originalMinor: original,
          valueMinor: v,
          counted: counted,
          note: note));
    }

    // ---- Cash ----
    int walletNow = 0;
    bool walletsValued = true;
    for (final ZakatCash x in c.cash) {
      if (!fresh(x.key)) continue;
      final bool inWallets = (x.kind == CashKind.goal || x.kind == CashKind.project) &&
          !x.heldOutsideWallets;
      add(x.key, ZakatSection.cash, x.currency, x.amountMinor,
          inWallets ? LineNote.insideWallets : LineNote.counted);
      if (x.kind == CashKind.wallet) {
        final ZakatLine l = lines.last;
        if (l.note == LineNote.unvalued) walletsValued = false;
        walletNow += l.valueMinor;
      }
    }

    // ---- Hawl ----
    ZakatHawl? hawl;
    final DateTime? start = c.hawlStart;
    if (start == null) {
      issue(ZakatIssueCode.hawlStartMissing);
    } else {
      hawl = ZakatHawl.from(start, adjustDays: c.hawlAdjustDays);
      if (!hawl.completeOn(d)) issue(ZakatIssueCode.beforeHawlEnd);
    }

    // Wallet cash during the hawl, for the policies that need it.
    final List<BalancePoint>? history = c.cashHistory;
    int? balanceAt(DateTime t) {
      if (history == null) return null;
      int? v;
      for (final BalancePoint p in history) {
        if (!p.at.isAfter(t)) v = p.totalMinor;
      }
      return v;
    }

    int? lowestDuring(DateTime from, DateTime to) {
      final int? first = balanceAt(from);
      if (first == null) return null;
      int low = first;
      for (final BalancePoint p in history!) {
        if (p.at.isAfter(from) && !p.at.isAfter(to) && p.totalMinor < low) {
          low = p.totalMinor;
        }
      }
      return low;
    }

    int acquired = 0;
    if (rules.acquiredWealth == AcquiredWealthPolicy.minimumBalance &&
        walletsValued) {
      final int? low =
          (hawl == null) ? null : lowestDuring(hawl.start, d);
      if (low == null) {
        issue(ZakatIssueCode.historyMissing);
      } else if (low < walletNow) {
        // Money that came in during the hawl starts its own hawl.
        acquired = low - walletNow;
        lines.add(ZakatLine(
            key: 'acquired-during-hawl',
            section: ZakatSection.cash,
            currency: cur,
            originalMinor: low - walletNow,
            valueMinor: low - walletNow,
            counted: true,
            note: LineNote.acquiredDuringHawl));
      }
    }

    // ---- Gold, silver and other metals ----
    final bool anyRegisteredMetal = c.metals.isNotEmpty;
    for (final ZakatMetal m in c.metals) {
      if (!fresh(m.key)) continue;
      if (m.metal == ZakatMetalKind.other) {
        final int? v = m.marketValueMinor;
        final String mc = m.currency ?? cur;
        if (m.use == MetalUse.trade && v != null) {
          add(m.key, ZakatSection.metal, mc, v, LineNote.counted);
        } else {
          add(m.key, ZakatSection.metal, mc, v ?? 0, LineNote.notZakatableMetal);
        }
        continue;
      }
      if (m.use == MetalUse.adornment &&
          rules.wornJewelry == WornJewelryPolicy.exempt) {
        add(m.key, ZakatSection.metal, cur, 0, LineNote.adornmentExempt);
        continue;
      }
      if (m.use == MetalUse.unspecified) {
        issue(ZakatIssueCode.metalUseUnspecified, ref: m.key);
      }
      final bool gold = m.metal == ZakatMetalKind.gold;
      final MetalPriceQuote? price = gold ? c.goldPrice : c.silverPrice;
      if (price == null) {
        issue(gold
            ? ZakatIssueCode.missingGoldPrice
            : ZakatIssueCode.missingSilverPrice);
        lines.add(ZakatLine(
            key: m.key,
            section: ZakatSection.metal,
            currency: cur,
            originalMinor: 0,
            valueMinor: 0,
            counted: false,
            note: LineNote.unvalued));
        continue;
      }
      final int value = pureMetalValue(
          metal: m.metal,
          grossMilligrams: m.grossMilligrams,
          purity: m.purity,
          perPureGramMinor: price.perPureGramMinor,
          rounding: rules.rounding);
      add(m.key, ZakatSection.metal, cur, value, LineNote.counted, value: value);
    }

    // ---- Investments ----
    for (final ZakatInvestment i in c.investments) {
      if (!fresh(i.key)) continue;
      switch (i.kind) {
        case InvestmentKind.tradingShares:
        case InvestmentKind.tradeGoods:
          add(i.key, ZakatSection.investment, i.currency, i.marketValueMinor,
              LineNote.counted);
        case InvestmentKind.rentalProperty:
          add(i.key, ZakatSection.investment, i.currency, i.marketValueMinor,
              LineNote.rentalPropertyExcluded);
        case InvestmentKind.retainedShares:
          {
          final int? part = i.zakatablePartMinor;
          if (rules.retainedShares ==
                  RetainedSharesPolicy.zakatablePartElseFullValue &&
              part != null) {
            final int? v = toBase(part, i.currency);
            add(i.key, ZakatSection.investment, i.currency, i.marketValueMinor,
                v == null ? LineNote.counted : LineNote.zakatablePart,
                value: v);
          } else {
            if (rules.retainedShares ==
                RetainedSharesPolicy.zakatablePartElseFullValue) {
              issue(ZakatIssueCode.retainedSharesFullValue, ref: i.key);
            }
            add(i.key, ZakatSection.investment, i.currency, i.marketValueMinor,
                LineNote.fullValueFallback);
          }
          }
        case InvestmentKind.unspecified:
          issue(ZakatIssueCode.investmentKindUnspecified, ref: i.key);
          add(i.key, ZakatSection.investment, i.currency, i.marketValueMinor,
              LineNote.fullValueFallback);
      }
    }

    // ---- What others owe the user ----
    for (final ZakatReceivable r in c.receivables) {
      if (!fresh(r.key)) continue;
      final LineNote note = !r.collectible
          ? LineNote.doubtfulReceivable
          : rules.receivables == ReceivablesPolicy.onReceipt
              ? LineNote.untilReceived
              : LineNote.counted;
      add(r.key, ZakatSection.receivable, r.currency, r.amountMinor, note);
    }

    // ---- Entered by hand ----
    for (final ZakatManual x in c.manual) {
      if (!fresh(x.key)) continue;
      if (x.kind == ManualKind.metal && anyRegisteredMetal) {
        issue(ZakatIssueCode.manualMetalMayDuplicate, ref: x.key);
      }
      add(x.key, ZakatSection.manual, x.currency, x.amountMinor, LineNote.counted);
    }

    // ---- The user's own debts ----
    final DateTime in12Months = DateTime(d.year + 1, d.month, d.day);
    for (final ZakatDebt x in c.debts) {
      if (!fresh(x.key)) continue;
      final DateTime? due = x.dueDate;
      final bool deduct = switch (rules.debtDeduction) {
        DebtDeductionPolicy.none => false,
        DebtDeductionPolicy.all => true,
        DebtDeductionPolicy.dueByZakatDate => due == null || !due.isAfter(d),
        DebtDeductionPolicy.dueWithin12Months =>
          due == null || !due.isAfter(in12Months),
      };
      add(x.key, ZakatSection.debt, x.currency, x.amountMinor,
          deduct ? LineNote.counted : LineNote.notDeducted);
    }

    // ---- Totals ----
    int assets = 0;
    int deductions = 0;
    for (final ZakatLine l in lines) {
      if (!l.counted) continue;
      if (l.section == ZakatSection.debt) {
        deductions += l.valueMinor;
      } else {
        assets += l.valueMinor;
      }
    }
    final int base = assets - deductions < 0 ? 0 : assets - deductions;

    // ---- Nisab ----
    final ZakatNisab? nisab = _nisab(c, d, issue);

    // ---- Nisab over the hawl ----
    final int nisabAmount = nisab?.amountMinor ?? 0;
    bool nisabMet = nisab != null && nisabAmount > 0 && base >= nisabAmount;
    if (nisabMet && hawl != null) {
      // What the user held besides wallet cash is taken as unchanged.
      final int nonWallet = base - walletNow - acquired;
      int? wealthAt(DateTime t) {
        final int? w = balanceAt(t);
        return w == null ? null : w + nonWallet;
      }

      final int? atStart = wealthAt(hawl.start);
      if (atStart == null) {
        issue(ZakatIssueCode.historyMissing);
      } else if (rules.nisabContinuity == NisabContinuity.startAndEnd) {
        if (atStart < nisabAmount) {
          issue(ZakatIssueCode.nisabNotMetAtHawlStart, at: hawl.start);
          nisabMet = false;
        }
      } else {
        DateTime? dropped;
        if (atStart < nisabAmount) dropped = hawl.start;
        for (final BalancePoint p in history!) {
          if (dropped != null) break;
          if (p.at.isAfter(hawl.start) &&
              !p.at.isAfter(d) &&
              p.totalMinor + nonWallet < nisabAmount) {
            dropped = p.at;
          }
        }
        if (dropped != null) {
          issue(ZakatIssueCode.droppedBelowNisab, at: dropped);
          nisabMet = false;
        }
      }
    }

    final int due = nisabMet
        ? ZakatMoney.divide(BigInt.from(base) * BigInt.from(rules.rateBasisPoints),
            BigInt.from(10000), rules.rounding)
        : 0;

    if (!rules.approved) issue(ZakatIssueCode.rulesNotApproved);
    final bool blocked = issues.any((ZakatIssue i) => i.blocking);
    final ZakatStatus status = blocked
        ? ZakatStatus.incomplete
        : issues.isEmpty
            ? ZakatStatus.final_
            : ZakatStatus.provisional;

    return ZakatOutcome(
      status: status,
      currency: cur,
      zakatDate: d,
      rules: rules,
      issues: List<ZakatIssue>.unmodifiable(issues),
      lines: List<ZakatLine>.unmodifiable(lines),
      assetsMinor: assets,
      deductionsMinor: deductions,
      baseMinor: base,
      nisab: nisab,
      hawl: hawl,
      nisabMet: !blocked && nisabMet,
      obligatoryNow: !blocked && nisabMet && hawl != null && hawl.completeOn(d),
      dueMinor: blocked ? 0 : due,
      fxUsed: List<FxQuote>.unmodifiable(usedFx.values),
    );
  }

  /// [grossMilligrams] of [metal] at [purity] (karats of 24 for gold, parts
  /// per thousand for silver), at [perPureGramMinor] per gram of pure metal.
  static int pureMetalValue({
    required ZakatMetalKind metal,
    required int grossMilligrams,
    required int purity,
    required int perPureGramMinor,
    RoundingPolicy rounding = RoundingPolicy.halfUp,
  }) {
    final int den = metal == ZakatMetalKind.gold ? 24 : 1000;
    return ZakatMoney.divide(
        BigInt.from(grossMilligrams) *
            BigInt.from(purity) *
            BigInt.from(perPureGramMinor),
        BigInt.from(den) * BigInt.from(1000),
        rounding);
  }

  static ZakatNisab? _nisab(ZakatCase c, DateTime d,
      void Function(ZakatIssueCode, {String? ref, DateTime? at}) issue) {
    switch (c.rules.nisabBasis) {
      case NisabBasis.gold:
        final MetalPriceQuote? p = c.goldPrice;
        if (p == null) {
          issue(ZakatIssueCode.missingGoldPrice);
          return null;
        }
        return ZakatNisab(
            basis: NisabBasis.gold,
            amountMinor: goldNisabGrams * p.perPureGramMinor,
            source: p.source,
            asOf: p.asOf,
            grams: goldNisabGrams,
            karat: 24,
            gramPriceMinor: p.perPureGramMinor);
      case NisabBasis.silver:
        final MetalPriceQuote? p = c.silverPrice;
        if (p == null) {
          issue(ZakatIssueCode.missingSilverPrice);
          return null;
        }
        return ZakatNisab(
            basis: NisabBasis.silver,
            amountMinor: silverNisabGrams * p.perPureGramMinor,
            source: p.source,
            asOf: p.asOf,
            grams: silverNisabGrams,
            gramPriceMinor: p.perPureGramMinor);
      case NisabBasis.official:
        final OfficialNisab? n = c.profile.officialFor(d);
        if (n == null || n.currency != c.profile.currency) {
          issue(ZakatIssueCode.missingOfficialNisab);
          return null;
        }
        // An announcement covers its own Hijri year (it is published at the
        // start of the next one); older than that is shown as the latest
        // documented value, not as the current one.
        if (HijriDate.fromGregorian(d).year - n.hijriYear > 1) {
          issue(ZakatIssueCode.officialNisabStale, ref: '${n.hijriYear}');
        }
        return ZakatNisab(
            basis: NisabBasis.official,
            amountMinor: n.amountMinor,
            source: n.sourceUrl,
            asOf: n.announcedOn,
            hijriYear: n.hijriYear,
            grams: n.grams,
            karat: n.goldKarat,
            gramPriceMinor: n.gramPriceMinor);
    }
  }
}
