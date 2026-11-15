import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/zakat/domain/engine/profiles/algeria_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_case.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_engine.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_hawl.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_money.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';

/// DZD has 2 decimals: 1 DZD = 100 minor units.
int dzd(int whole) => whole * 100;

// Ends in July 2026, after the 1447 nisab was announced (18 June 2026).
final DateTime hawlStart = DateTime(2025, 8, 1);
final ZakatHawl hawl = ZakatHawl.from(hawlStart);
final ZakatRules maliki = algeriaZakatProfile.defaultRules;

/// A neutral baseline for the arithmetic tests (each policy is set where a
/// test is about it): money joins the hawl, start and end count, receivables
/// are added yearly.
final ZakatRules approved = maliki.copyWith(
    school: ZakatSchool.custom,
    acquiredWealth: AcquiredWealthPolicy.joinToHawl,
    nisabContinuity: NisabContinuity.startAndEnd,
    receivables: ReceivablesPolicy.yearly);
final ZakatRules draft = approved.copyWith(approved: false);

/// Pure gold at 36,000 DZD/g (the 18k price 27,000 scaled to 24k).
final MetalPriceQuote gold =
    MetalPriceQuote(perPureGramMinor: dzd(36000), asOf: hawl.end, source: 'test');

ZakatCase caseOf({
  ZakatRules? rules,
  DateTime? date,
  DateTime? start,
  int adjust = 0,
  List<ZakatCash> cash = const <ZakatCash>[],
  List<BalancePoint>? history,
  List<ZakatMetal> metals = const <ZakatMetal>[],
  MetalPriceQuote? goldPrice,
  MetalPriceQuote? silverPrice,
  List<ZakatInvestment> investments = const <ZakatInvestment>[],
  List<ZakatReceivable> receivables = const <ZakatReceivable>[],
  List<ZakatDebt> debts = const <ZakatDebt>[],
  List<ZakatManual> manual = const <ZakatManual>[],
  List<FxQuote> fx = const <FxQuote>[],
  bool noStart = false,
}) =>
    ZakatCase(
      profile: algeriaZakatProfile,
      rules: rules ?? approved.copyWith(nisabBasis: NisabBasis.official),
      zakatDate: date ?? hawl.end,
      hawlStart: noStart ? null : (start ?? hawlStart),
      hawlAdjustDays: adjust,
      cash: cash,
      cashHistory: history,
      metals: metals,
      goldPrice: goldPrice,
      silverPrice: silverPrice,
      investments: investments,
      receivables: receivables,
      debts: debts,
      manual: manual,
      fx: fx,
    );

ZakatCash wallet(String id, int minor, {String currency = 'DZD'}) => ZakatCash(
    key: 'wallet:$id', kind: CashKind.wallet, currency: currency, amountMinor: minor);

/// Wallet cash constant over the hawl.
List<BalancePoint> flat(int minor) => <BalancePoint>[BalancePoint(hawlStart, minor)];

void main() {
  group('the 2.5% and rounding', () {
    test('2.5% of the base', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          cash: <ZakatCash>[wallet('general', dzd(4000000))],
          history: flat(dzd(4000000))));
      expect(o.status, ZakatStatus.final_);
      expect(o.baseMinor, dzd(4000000));
      expect(o.dueMinor, dzd(100000));
      expect(o.obligatoryNow, isTrue);
    });

    test('each rounding policy, stated in the rules', () {
      // A tiny silver nisab so a base of 1,001 minor units is above it.
      final MetalPriceQuote silver =
          MetalPriceQuote(perPureGramMinor: 1, asOf: hawl.end, source: 't');
      int due(RoundingPolicy r) => ZakatEngine.compute(caseOf(
              rules: approved.copyWith(
                  nisabBasis: NisabBasis.silver, rounding: r),
              silverPrice: silver,
              cash: <ZakatCash>[wallet('w', 1001)],
              history: flat(1001)))
          .dueMinor;
      expect(due(RoundingPolicy.halfUp), 25); // 25.025
      expect(due(RoundingPolicy.up), 26);
      expect(due(RoundingPolicy.down), 25);
    });

    test('very large amounts stay exact', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(manual: <ZakatManual>[
        const ZakatManual(
            key: 'manual:big',
            kind: ManualKind.cash,
            currency: 'DZD',
            amountMinor: 900000000000000000),
      ], history: flat(0)));
      expect(o.dueMinor, 22500000000000000);
    });

    test('currencies with 0 and 3 decimals convert exactly', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
        cash: <ZakatCash>[
          wallet('yen', 1000, currency: 'JPY'), // 1,000 JPY
          wallet('kwd', 1000, currency: 'KWD'), // 1.000 KWD
        ],
        fx: <FxQuote>[
          FxQuote.parse(
              from: 'JPY', to: 'DZD', rate: '0.9', asOf: hawl.end, source: 't')!,
          FxQuote.parse(
              from: 'KWD', to: 'DZD', rate: '440', asOf: hawl.end, source: 't')!,
        ],
      ));
      expect(o.lines[0].valueMinor, dzd(900));
      expect(o.lines[1].valueMinor, dzd(440));
      expect(o.fxUsed.length, 2);
    });

    test('debts larger than the assets give a zero base, never negative', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
        cash: <ZakatCash>[wallet('w', dzd(100))],
        debts: const <ZakatDebt>[
          ZakatDebt(key: 'debt:1', currency: 'DZD', amountMinor: 500000)
        ],
      ));
      expect(o.baseMinor, 0);
      expect(o.dueMinor, 0);
      expect(o.nisabMet, isFalse);
    });
  });

  group('nisab', () {
    test('the official 1447 nisab is 85 g of 18k gold at 27,000 DZD', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf());
      expect(o.nisab!.amountMinor, dzd(2295000));
      expect(o.nisab!.amountMinor, 85 * dzd(27000));
      expect(o.nisab!.karat, 18);
      expect(o.nisab!.hijriYear, 1447);
      expect(o.nisab!.source, contains('radioalgerie'));
    });

    test('one unit below, equal, above', () {
      bool met(int minor) => ZakatEngine.compute(caseOf(
              cash: <ZakatCash>[wallet('w', minor)], history: flat(minor)))
          .nisabMet;
      expect(met(dzd(2295000) - 1), isFalse);
      expect(met(dzd(2295000)), isTrue);
      expect(met(dzd(2295000) + 1), isTrue);
    });

    test('pure-gold nisab is higher than the official 18k one', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          rules: approved.copyWith(nisabBasis: NisabBasis.gold),
          goldPrice: gold,
          cash: <ZakatCash>[wallet('w', dzd(2500000))],
          history: flat(dzd(2500000))));
      expect(o.nisab!.amountMinor, 85 * dzd(36000)); // 3,060,000 DZD
      expect(o.nisabMet, isFalse); // but it meets the official one
      // 85 g of 18k gold is worth exactly the official nisab.
      expect(
          ZakatEngine.pureMetalValue(
              metal: ZakatMetalKind.gold,
              grossMilligrams: 85000,
              purity: 18,
              perPureGramMinor: dzd(36000)),
          dzd(2295000));
    });

    test('gold against silver', () {
      final MetalPriceQuote silver =
          MetalPriceQuote(perPureGramMinor: dzd(400), asOf: hawl.end, source: 't');
      ZakatOutcome on(NisabBasis b) => ZakatEngine.compute(caseOf(
          rules: approved.copyWith(nisabBasis: b),
          goldPrice: gold,
          silverPrice: silver,
          cash: <ZakatCash>[wallet('w', dzd(1000000))],
          history: flat(dzd(1000000))));
      expect(on(NisabBasis.silver).nisab!.amountMinor, 595 * dzd(400));
      expect(on(NisabBasis.silver).nisabMet, isTrue);
      expect(on(NisabBasis.gold).nisabMet, isFalse);
    });

    test('no gold price: no amount, never a guess', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          rules: approved.copyWith(nisabBasis: NisabBasis.gold),
          cash: <ZakatCash>[wallet('w', dzd(9000000))]));
      expect(o.status, ZakatStatus.incomplete);
      expect(o.has(ZakatIssueCode.missingGoldPrice), isTrue);
      expect(o.dueMinor, 0);
    });

    test('an old announcement is shown as the latest documented one', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          date: DateTime(2028, 9, 1), start: DateTime(2027, 9, 1)));
      expect(o.nisab!.hijriYear, 1447);
      expect(o.has(ZakatIssueCode.officialNisabStale), isTrue);
      expect(o.status, isNot(ZakatStatus.final_));
    });

    test('before the 1447 announcement, the 1446 value applies', () {
      expect(algeriaZakatProfile.officialFor(DateTime(2026, 6, 1))!.hijriYear,
          1446);
      expect(algeriaZakatProfile.officialFor(DateTime(2026, 6, 18))!.hijriYear,
          1447);
    });
  });

  group('hawl', () {
    test('the day before it ends: an estimate, not due yet', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          date: hawl.end.subtract(const Duration(days: 1)),
          cash: <ZakatCash>[wallet('w', dzd(4000000))],
          history: flat(dzd(4000000))));
      expect(o.obligatoryNow, isFalse);
      expect(o.has(ZakatIssueCode.beforeHawlEnd), isTrue);
      expect(o.status, ZakatStatus.provisional);
      expect(o.dueMinor, dzd(100000)); // shown as an estimate
    });

    test('the day it ends: due', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          cash: <ZakatCash>[wallet('w', dzd(4000000))],
          history: flat(dzd(4000000))));
      expect(o.obligatoryNow, isTrue);
    });

    test('the end can be moved one day either way', () {
      expect(ZakatHawl.from(hawlStart, adjustDays: 1).end,
          hawl.end.add(const Duration(days: 1)));
      expect(ZakatHawl.from(hawlStart, adjustDays: -1).end,
          hawl.end.subtract(const Duration(days: 1)));
      expect(() => ZakatHawl.from(hawlStart, adjustDays: 2),
          throwsArgumentError);
    });

    test('it ends on the same Hijri day a year later, the 30th included', () {
      int thirties = 0;
      for (int i = 0; i < 1200; i++) {
        final DateTime s = DateTime(2024, 1, 1).add(Duration(days: i));
        final HijriDate h = HijriDate.fromGregorian(s);
        final HijriDate e = HijriDate.fromGregorian(ZakatHawl.from(s).end);
        expect(e.year, h.year + 1, reason: '$s');
        expect(e.month, h.month, reason: '$s');
        expect(e.day, lessThanOrEqualTo(h.day), reason: '$s');
        if (h.day == 30) thirties++;
      }
      expect(thirties, greaterThan(0));
    });

    test('no start date: not due, never final', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          noStart: true, cash: <ZakatCash>[wallet('w', dzd(4000000))]));
      expect(o.has(ZakatIssueCode.hawlStartMissing), isTrue);
      expect(o.obligatoryNow, isFalse);
      expect(o.status, ZakatStatus.provisional);
    });

    test('a drop below nisab during the hawl, per policy', () {
      final DateTime mid = hawlStart.add(const Duration(days: 150));
      final List<BalancePoint> h = <BalancePoint>[
        BalancePoint(hawlStart, dzd(3000000)),
        BalancePoint(mid, dzd(1000000)),
        BalancePoint(mid.add(const Duration(days: 30)), dzd(3000000)),
      ];
      ZakatOutcome on(NisabContinuity p) => ZakatEngine.compute(caseOf(
          rules: approved.copyWith(
              nisabBasis: NisabBasis.official, nisabContinuity: p),
          cash: <ZakatCash>[wallet('w', dzd(3000000))],
          history: h));
      expect(on(NisabContinuity.startAndEnd).obligatoryNow, isTrue);
      final ZakatOutcome t = on(NisabContinuity.throughout);
      expect(t.obligatoryNow, isFalse);
      expect(t.issues
          .firstWhere((ZakatIssue i) => i.code == ZakatIssueCode.droppedBelowNisab)
          .at, mid);
    });

    test('below nisab at the start of the hawl: not due', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          cash: <ZakatCash>[wallet('w', dzd(3000000))],
          history: <BalancePoint>[
            BalancePoint(hawlStart, dzd(1000000)),
            BalancePoint(hawlStart.add(const Duration(days: 300)), dzd(3000000)),
          ]));
      expect(o.has(ZakatIssueCode.nisabNotMetAtHawlStart), isTrue);
      expect(o.obligatoryNow, isFalse);
    });
  });

  group('money that came in during the hawl', () {
    final List<BalancePoint> salaryAtEnd = <BalancePoint>[
      BalancePoint(hawlStart, dzd(3000000)),
      BalancePoint(hawl.end.subtract(const Duration(days: 3)), dzd(4000000)),
    ];
    final List<BalancePoint> midYear = <BalancePoint>[
      BalancePoint(hawlStart, dzd(3000000)),
      BalancePoint(hawlStart.add(const Duration(days: 180)), dzd(3500000)),
    ];
    ZakatOutcome on(AcquiredWealthPolicy p, List<BalancePoint> h, int now) =>
        ZakatEngine.compute(caseOf(
            rules: approved.copyWith(
                nisabBasis: NisabBasis.official, acquiredWealth: p),
            cash: <ZakatCash>[wallet('w', now)],
            history: h));

    test('a salary just before the end', () {
      expect(on(AcquiredWealthPolicy.joinToHawl, salaryAtEnd, dzd(4000000))
          .baseMinor, dzd(4000000));
      final ZakatOutcome b =
          on(AcquiredWealthPolicy.minimumBalance, salaryAtEnd, dzd(4000000));
      expect(b.baseMinor, dzd(3000000));
      expect(b.lines.any((ZakatLine l) => l.note == LineNote.acquiredDuringHawl),
          isTrue);
    });

    test('money that came in mid-year', () {
      expect(on(AcquiredWealthPolicy.joinToHawl, midYear, dzd(3500000))
          .dueMinor, dzd(87500));
      expect(on(AcquiredWealthPolicy.minimumBalance, midYear, dzd(3500000))
          .dueMinor, dzd(75000));
    });

    test('no history for the minimum-balance policy: said, not hidden', () {
      final ZakatOutcome o =
          on(AcquiredWealthPolicy.minimumBalance, const <BalancePoint>[], dzd(4000000));
      expect(o.has(ZakatIssueCode.historyMissing), isTrue);
      expect(o.status, isNot(ZakatStatus.final_));
    });
  });

  group('nothing is counted twice', () {
    test('a goal inside the wallets is not added; one outside is, once', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(cash: <ZakatCash>[
        wallet('general', dzd(3000000)),
        const ZakatCash(
            key: 'goal:car', kind: CashKind.goal, currency: 'DZD', amountMinor: 30000000),
        const ZakatCash(
            key: 'goal:hajj',
            kind: CashKind.goal,
            currency: 'DZD',
            amountMinor: 50000000,
            heldOutsideWallets: true),
      ], history: flat(dzd(3000000))));
      expect(o.assetsMinor, dzd(3000000) + 50000000);
      expect(o.lines.firstWhere((ZakatLine l) => l.key == 'goal:car').note,
          LineNote.insideWallets);
    });

    test('an old project restored twice counts once', () {
      const ZakatCash p = ZakatCash(
          key: 'project:p1',
          kind: CashKind.project,
          currency: 'DZD',
          amountMinor: 10000000,
          heldOutsideWallets: true);
      final ZakatOutcome o =
          ZakatEngine.compute(caseOf(cash: <ZakatCash>[p, p], history: flat(0)));
      expect(o.assetsMinor, 10000000);
      expect(o.has(ZakatIssueCode.duplicateSource), isTrue);
    });

    test('a transfer between wallets changes nothing', () {
      int base(int a, int b) => ZakatEngine.compute(caseOf(
              cash: <ZakatCash>[wallet('a', a), wallet('b', b)]))
          .assetsMinor;
      expect(base(dzd(1000), dzd(2000)), base(dzd(2500), dzd(500)));
    });

    test('a registered metal and a hand-entered metal value: warned', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
        goldPrice: gold,
        metals: const <ZakatMetal>[
          ZakatMetal(
              key: 'metal:ring',
              metal: ZakatMetalKind.gold,
              grossMilligrams: 10000,
              purity: 18,
              use: MetalUse.savings),
        ],
        manual: const <ZakatManual>[
          ZakatManual(
              key: 'manual:metals',
              kind: ManualKind.metal,
              currency: 'DZD',
              amountMinor: 27000000),
        ],
      ));
      expect(o.has(ZakatIssueCode.manualMetalMayDuplicate), isTrue);
    });
  });

  group('metals', () {
    ZakatOutcome metal(MetalUse use, int karat,
            {WornJewelryPolicy p = WornJewelryPolicy.exempt}) =>
        ZakatEngine.compute(caseOf(
            rules: approved.copyWith(
                nisabBasis: NisabBasis.official, wornJewelry: p),
            goldPrice: gold,
            history: flat(0),
            metals: <ZakatMetal>[
              ZakatMetal(
                  key: 'metal:1',
                  metal: ZakatMetalKind.gold,
                  grossMilligrams: 100000, // 100 g
                  purity: karat,
                  use: use),
            ]));

    test('18, 21 and 24 karat are valued by their pure gold', () {
      expect(metal(MetalUse.savings, 24).assetsMinor, dzd(3600000));
      expect(metal(MetalUse.savings, 21).assetsMinor, dzd(3150000));
      expect(metal(MetalUse.savings, 18).assetsMinor, dzd(2700000));
    });

    test('worn jewellery follows the rule; savings and trade count', () {
      expect(metal(MetalUse.adornment, 18).assetsMinor, 0);
      expect(
          metal(MetalUse.adornment, 18, p: WornJewelryPolicy.zakatable).assetsMinor,
          dzd(2700000));
      expect(metal(MetalUse.trade, 18).assetsMinor, dzd(2700000));
    });

    test('a piece with no stated use counts, with a warning', () {
      final ZakatOutcome o = metal(MetalUse.unspecified, 18);
      expect(o.assetsMinor, dzd(2700000));
      expect(o.has(ZakatIssueCode.metalUseUnspecified), isTrue);
    });

    test('silver by parts per thousand', () {
      expect(
          ZakatEngine.pureMetalValue(
              metal: ZakatMetalKind.silver,
              grossMilligrams: 1000000, // 1 kg
              purity: 925,
              perPureGramMinor: dzd(400)),
          dzd(370000));
    });
  });

  group('investments', () {
    ZakatOutcome inv(ZakatInvestment i) =>
        ZakatEngine.compute(caseOf(investments: <ZakatInvestment>[i]));

    test('trading shares: full market value', () {
      expect(
          inv(const ZakatInvestment(
                  key: 'inv:1',
                  kind: InvestmentKind.tradingShares,
                  currency: 'DZD',
                  marketValueMinor: 100000000))
              .assetsMinor,
          100000000);
    });

    test('retained shares: the zakatable part when known', () {
      final ZakatOutcome o = inv(const ZakatInvestment(
          key: 'inv:2',
          kind: InvestmentKind.retainedShares,
          currency: 'DZD',
          marketValueMinor: 100000000,
          zakatablePartMinor: 30000000));
      expect(o.assetsMinor, 30000000);
      expect(o.lines.single.note, LineNote.zakatablePart);
    });

    test('retained shares, part unknown: full value, with a warning', () {
      final ZakatOutcome o = inv(const ZakatInvestment(
          key: 'inv:3',
          kind: InvestmentKind.retainedShares,
          currency: 'DZD',
          marketValueMinor: 100000000));
      expect(o.assetsMinor, 100000000);
      expect(o.has(ZakatIssueCode.retainedSharesFullValue), isTrue);
    });

    test('a rental property: its value is not zakatable', () {
      expect(
          inv(const ZakatInvestment(
                  key: 'inv:4',
                  kind: InvestmentKind.rentalProperty,
                  currency: 'DZD',
                  marketValueMinor: 900000000))
              .assetsMinor,
          0);
    });
  });

  group('debts and receivables', () {
    final List<ZakatDebt> debts = <ZakatDebt>[
      ZakatDebt(
          key: 'debt:due',
          currency: 'DZD',
          amountMinor: 1000,
          dueDate: hawl.end.subtract(const Duration(days: 10))),
      ZakatDebt(
          key: 'debt:soon',
          currency: 'DZD',
          amountMinor: 2000,
          dueDate: hawl.end.add(const Duration(days: 100))),
      ZakatDebt(
          key: 'debt:later',
          currency: 'DZD',
          amountMinor: 4000,
          dueDate: hawl.end.add(const Duration(days: 900))),
      const ZakatDebt(key: 'debt:noterm', currency: 'DZD', amountMinor: 8000),
    ];
    int deducted(DebtDeductionPolicy p) => ZakatEngine.compute(caseOf(
            rules: approved.copyWith(
                nisabBasis: NisabBasis.official, debtDeduction: p),
            debts: debts))
        .deductionsMinor;

    test('which debts are deducted, per policy', () {
      expect(deducted(DebtDeductionPolicy.none), 0);
      expect(deducted(DebtDeductionPolicy.dueByZakatDate), 1000 + 8000);
      expect(deducted(DebtDeductionPolicy.dueWithin12Months), 1000 + 2000 + 8000);
      expect(deducted(DebtDeductionPolicy.all), 15000);
    });

    test('a doubtful receivable is not added; others per policy', () {
      const List<ZakatReceivable> r = <ZakatReceivable>[
        ZakatReceivable(key: 'r:ok', currency: 'DZD', amountMinor: 5000),
        ZakatReceivable(
            key: 'r:doubt', currency: 'DZD', amountMinor: 7000, collectible: false),
      ];
      int added(ReceivablesPolicy p) => ZakatEngine.compute(caseOf(
              rules: approved.copyWith(
                  nisabBasis: NisabBasis.official, receivables: p),
              receivables: r))
          .assetsMinor;
      expect(added(ReceivablesPolicy.yearly), 5000);
      expect(added(ReceivablesPolicy.onReceipt), 0);
    });
  });

  group('currencies', () {
    test('a euro asset in a dinar calculation, at the dated rate', () {
      final FxQuote eur = FxQuote.parse(
          from: 'EUR', to: 'DZD', rate: '150.5', asOf: hawl.end, source: 'bank')!;
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          cash: <ZakatCash>[wallet('eur', 100000, currency: 'EUR')], // 1,000 EUR
          fx: <FxQuote>[eur]));
      expect(o.assetsMinor, dzd(150500));
      expect(o.fxUsed.single.source, 'bank');
      expect(o.fxUsed.single.asOf, hawl.end);
    });

    test('a missing rate stops the result; the asset is not dropped', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(cash: <ZakatCash>[
        wallet('general', dzd(4000000)),
        wallet('eur', 100000, currency: 'EUR'),
      ]));
      expect(o.status, ZakatStatus.incomplete);
      expect(o.has(ZakatIssueCode.missingRate), isTrue);
      expect(o.dueMinor, 0);
      expect(o.lines.firstWhere((ZakatLine l) => l.key == 'wallet:eur').note,
          LineNote.unvalued);
    });

    test('an unknown currency is refused, not read as USD', () {
      final ZakatOutcome o = ZakatEngine.compute(
          caseOf(cash: <ZakatCash>[wallet('x', 100, currency: 'XYZ')]));
      expect(o.has(ZakatIssueCode.unknownCurrency), isTrue);
      expect(o.status, ZakatStatus.incomplete);
    });

    test('rates are parsed exactly, never as doubles', () {
      expect(ZakatMoney.parseScaled('0.1', 8), BigInt.from(10000000));
      expect(ZakatMoney.parseScaled('1.123456789', 8), isNull);
      expect(ZakatMoney.parseScaled('-1', 8), isNull);
    });
  });

  group('rules', () {
    test('unapproved rules never give a final result', () {
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
          rules: draft,
          goldPrice: gold,
          cash: <ZakatCash>[wallet('w', dzd(4000000))],
          history: flat(dzd(4000000))));
      expect(o.has(ZakatIssueCode.rulesNotApproved), isTrue);
      expect(o.status, ZakatStatus.provisional);
    });

    test('saved rules read back unchanged', () {
      final ZakatRules r = approved.copyWith(
          acquiredWealth: AcquiredWealthPolicy.minimumBalance,
          rounding: RoundingPolicy.down);
      final ZakatRules back = ZakatRules.fromJson(r.toJson(), draft);
      expect(back.toJson(), r.toJson());
    });

    test('Algeria follows the Maliki school with the official nisab', () {
      expect(maliki.approved, isTrue);
      expect(maliki.school, ZakatSchool.maliki);
      expect(maliki.nisabBasis, NisabBasis.official);
      expect(maliki.acquiredWealth, AcquiredWealthPolicy.minimumBalance);
      expect(maliki.nisabContinuity, NisabContinuity.throughout);
      expect(maliki.wornJewelry, WornJewelryPolicy.exempt);
      expect(maliki.receivables, ReceivablesPolicy.onReceipt);
      expect(algeriaZakatProfile.currency, 'DZD');
      expect(maliki.rateBasisPoints, 250);
    });

    test('the school presets match what each school settles', () {
      expect(ZakatSchools.apply(ZakatSchool.maliki, approved).toJson(),
          maliki.toJson());
      final ZakatRules h = ZakatSchools.apply(ZakatSchool.hanafi, maliki);
      expect(h.school, ZakatSchool.hanafi);
      expect(h.acquiredWealth, AcquiredWealthPolicy.joinToHawl);
      expect(h.nisabContinuity, NisabContinuity.startAndEnd);
      expect(h.wornJewelry, WornJewelryPolicy.zakatable);
      expect(h.receivables, ReceivablesPolicy.yearly);
      // What no school settles is kept.
      expect(h.debtDeduction, maliki.debtDeduction);
      expect(h.nisabBasis, maliki.nisabBasis);
    });

    test('a full Maliki case, end to end', () {
      // 3,000,000 DZD all year, a 1,000,000 salary days before the end,
      // worn jewellery, a loan to a friend not yet repaid.
      final ZakatOutcome o = ZakatEngine.compute(caseOf(
        rules: maliki,
        goldPrice: gold,
        cash: <ZakatCash>[wallet('general', dzd(4000000))],
        history: <BalancePoint>[
          BalancePoint(hawlStart, dzd(3000000)),
          BalancePoint(hawl.end.subtract(const Duration(days: 3)), dzd(4000000)),
        ],
        metals: const <ZakatMetal>[
          ZakatMetal(
              key: 'metal:bracelet',
              metal: ZakatMetalKind.gold,
              grossMilligrams: 50000,
              purity: 18,
              use: MetalUse.adornment),
        ],
        receivables: const <ZakatReceivable>[
          ZakatReceivable(key: 'debt:friend', currency: 'DZD', amountMinor: 5000000),
        ],
      ));
      expect(o.status, ZakatStatus.final_);
      expect(o.nisab!.amountMinor, dzd(2295000));
      expect(o.baseMinor, dzd(3000000));
      expect(o.dueMinor, dzd(75000));
      expect(o.rules.school, ZakatSchool.maliki);
    });
  });
}
