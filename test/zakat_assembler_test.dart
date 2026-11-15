import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/zakat/application/zakat_engine_providers.dart';
import 'package:smartbudget/features/zakat/domain/engine/profiles/algeria_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_case.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_engine.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_market.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_money.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_settings.dart';
import 'package:smartbudget/features/zakat/domain/zakat_assembler.dart';

/// DZD has 2 decimals.
int dzd(int whole) => whole * 100;

final DateTime today = DateTime(2026, 11, 15);

/// A full lunar year before [today] (the 1447 nisab, 2,295,000 DZD, applies).
final DateTime start = DateTime(2025, 11, 1);
final DateTime created = DateTime(2025, 1, 1);

Wallet general(int whole, {String currency = 'DZD'}) =>
    Wallet.general(currency, opening: Money(dzd(whole), currency));

Wallet wallet(String id, int minor, String currency) => Wallet(
    id: id,
    name: id,
    type: WalletType.bank,
    opening: Money(minor, currency),
    createdAt: created);

Transaction txn(String id, DateTime date, int whole,
        {bool income = true, String? walletId}) =>
    Transaction(
        id: id,
        date: date,
        type: income ? TransactionType.income : TransactionType.expense,
        category: 'x',
        amount: Money(dzd(whole), 'DZD'),
        walletId: walletId,
        createdAt: date);

Goal goal(String id, int whole) => Goal(
    id: id,
    name: id,
    target: Money(dzd(whole * 2), 'DZD'),
    saved: Money(dzd(whole), 'DZD'),
    createdAt: created);

Debt debt(String id, DebtType type, int whole,
        {int paid = 0, DateTime? due, DateTime? on}) =>
    Debt(
        id: id,
        party: 'p',
        type: type,
        original: Money(dzd(whole), 'DZD'),
        paid: Money(dzd(paid), 'DZD'),
        date: on,
        dueDate: due,
        createdAt: created);

MetalHolding holding(String id, Metal metal, double grams, int purity) =>
    MetalHolding(
        id: id, metal: metal, grams: grams, purity: purity, createdAt: created);

final ZakatRules maliki = algeriaZakatProfile.defaultRules;

ZakatAssembly assemble(
  ZakatSources sources, {
  ZakatSettings? settings,
  DateTime? date,
}) {
  final ZakatSettings s = settings ?? ZakatSettings(hawlStart: start);
  return ZakatAssembler.build(
      profile: algeriaZakatProfile,
      rules: ZakatMarkets.rulesFor(algeriaZakatProfile, s),
      settings: s,
      sources: sources,
      zakatDate: date ?? today);
}

ZakatOutcome run(ZakatSources sources, {ZakatSettings? settings}) =>
    ZakatEngine.compute(assemble(sources, settings: settings).zakatCase);

ZakatLine line(ZakatOutcome o, String key) =>
    o.lines.firstWhere((ZakatLine l) => l.key == key);

bool hasLine(ZakatOutcome o, String key) =>
    o.lines.any((ZakatLine l) => l.key == key);

void main() {
  group('new user', () {
    test('no data and no settings: nothing due, the hawl start is asked for',
        () {
      final ZakatOutcome o =
          run(const ZakatSources(), settings: ZakatSettings.empty);
      expect(o.baseMinor, 0);
      expect(o.dueMinor, 0);
      expect(o.nisabMet, isFalse);
      expect(o.has(ZakatIssueCode.hawlStartMissing), isTrue);
      expect(o.nisab?.amountMinor, dzd(2295000));
    });

    test('settings default to the Maliki school with no market chosen', () {
      expect(ZakatSettings.empty.school, ZakatSchool.maliki);
      expect(ZakatSettings.empty.country, isNull);
      expect(ZakatSettings.empty.fromLegacy, isFalse);
    });
  });

  group('settings data', () {
    test('round-trips every field', () {
      final ZakatSettings s = ZakatSettings(
        country: 'DZ',
        hawlStart: start,
        hawlAdjustDays: -1,
        goldPerPureGramMinor: dzd(36000),
        silverPerPureGramMinor: dzd(250),
        priceCurrency: 'DZD',
        pricesAsOf: today,
        goalsHeldOutside: const <String>{'g1'},
        metalUses: const <String, MetalUse>{'m1': MetalUse.adornment},
        doubtfulReceivables: const <String>{'d1'},
        manual: <ZakatManual>[
          ZakatManual(
              key: 'manual:home',
              kind: ManualKind.cash,
              currency: 'DZD',
              amountMinor: dzd(1000)),
        ],
        investments: <ZakatInvestment>[
          ZakatInvestment(
              key: 'inv:1',
              kind: InvestmentKind.retainedShares,
              currency: 'DZD',
              marketValueMinor: dzd(5000),
              zakatablePartMinor: dzd(1000)),
        ],
      );
      final ZakatSettings back = ZakatSettings.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.toJson(), s.toJson());
      expect(back.hawlStart, start);
      expect(back.metalUses['m1'], MetalUse.adornment);
      expect(back.investments.single.zakatablePartMinor, dzd(1000));
    });

    test('unreadable fields fall back to "not set" without throwing', () {
      final ZakatSettings s = ZakatSettings.fromJson(<String, dynamic>{
        'country': 'algeria',
        'school': 'unknown',
        'hawlStart': 'never',
        'hawlAdjustDays': 9,
        'goldMinor': -5,
        'goalsOutside': 'g1',
        'metalUses': <String, dynamic>{'m1': 'worn', 'm2': 'savings'},
        'manual': <dynamic>[
          <String, dynamic>{'key': 'a', 'kind': 'cash', 'currency': 'DZD'},
          7,
        ],
      });
      expect(s.country, isNull);
      expect(s.school, ZakatSchool.maliki);
      expect(s.hawlStart, isNull);
      expect(s.hawlAdjustDays, 1);
      expect(s.goldPerPureGramMinor, isNull);
      expect(s.goalsHeldOutside, isEmpty);
      expect(s.metalUses, <String, MetalUse>{'m2': MetalUse.savings});
      expect(s.manual, isEmpty);
    });
  });

  group('older key (sb_zakat_inputs)', () {
    final Map<String, dynamic> legacy = <String, dynamic>{
      'gold': 36000.5,
      'silver': 250,
      'standard': 'silver',
      'hawlStart': '2025-11-01T00:00:00.000',
      'cash': 100000,
      'metals': 50000,
      'investments': 0,
    };

    test('maps its prices, hand-typed amounts and hawl start', () {
      final ZakatSettings s = ZakatSettings.fromLegacy(legacy, 'DZD');
      expect(s.fromLegacy, isTrue);
      expect(s.hawlStart, start);
      expect(s.goldPerPureGramMinor, 3600050);
      expect(s.silverPerPureGramMinor, dzd(250));
      expect(s.priceCurrency, 'DZD');
      expect(s.legacyStandard, 'silver');
      expect(s.school, ZakatSchool.maliki);
      expect(s.manual.map((ZakatManual m) => m.key),
          <String>['legacy:cash', 'legacy:metals']);
      expect(s.investments, isEmpty); // 0 is "nothing entered"
    });

    test('the silver standard chosen there does not change the Algerian nisab',
        () {
      final ZakatOutcome o = run(
          ZakatSources(wallets: <Wallet>[general(3000000)]),
          settings: ZakatSettings.fromLegacy(legacy, 'DZD'));
      expect(o.nisab?.basis, NisabBasis.official);
      expect(o.nisab?.amountMinor, dzd(2295000));
    });

    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    test('is read, never changed, and the new key wins once saved', () async {
      final String raw = jsonEncode(legacy);
      SharedPreferences.setMockInitialValues(
          <String, Object>{'sb_zakat_inputs_u1': raw});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final ZakatSettings first = ZakatSettingsStore.read(prefs, 'u1', 'DZD');
      expect(first.fromLegacy, isTrue);
      expect(first.hawlStart, start);
      expect(prefs.getString('sb_zakat_inputs_u1'), raw);
      expect(prefs.containsKey('sb_zakat_settings_u1'), isFalse);

      await ZakatSettingsStore.write(prefs, 'u1',
          first.copyWith(goalsHeldOutside: <String>{'g1'}));
      expect(prefs.getString('sb_zakat_inputs_u1'), raw);
      final ZakatSettings again = ZakatSettingsStore.read(prefs, 'u1', 'DZD');
      expect(again.fromLegacy, isFalse);
      expect(again.goalsHeldOutside, <String>{'g1'});
      expect(again.manual.length, 2); // the older amounts were carried over
    });

    test('a device-wide older key is read without being moved', () async {
      final String raw = jsonEncode(legacy);
      SharedPreferences.setMockInitialValues(
          <String, Object>{'sb_zakat_inputs': raw});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(ZakatSettingsStore.read(prefs, 'u1', 'DZD').fromLegacy, isTrue);
      expect(prefs.getString('sb_zakat_inputs'), raw);
      expect(prefs.containsKey('sb_zakat_inputs_u1'), isFalse);
    });

    test('another account never reads it; a corrupt value reads as not set',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sb_zakat_inputs_u1': jsonEncode(legacy),
        'sb_zakat_settings_u2': '{broken',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ZakatSettings u2 = ZakatSettingsStore.read(prefs, 'u2', 'DZD');
      expect(u2.fromLegacy, isFalse);
      expect(u2.hawlStart, isNull);
      expect(ZakatSettingsStore.read(prefs, null, 'DZD').hawlStart, isNull);
    });
  });

  group('older user with data', () {
    test('a whole year at 3,000,000 DZD: 75,000 due, final', () {
      final ZakatOutcome o =
          run(ZakatSources(wallets: <Wallet>[general(3000000)]));
      expect(o.baseMinor, dzd(3000000));
      expect(o.dueMinor, dzd(75000));
      expect(o.obligatoryNow, isTrue);
      expect(o.status, ZakatStatus.final_);
    });
  });

  group('missing data', () {
    test('a gold holding without any price blocks the amount', () {
      final ZakatOutcome o = run(ZakatSources(
          wallets: <Wallet>[general(3000000)],
          metals: <MetalHolding>[holding('m1', Metal.gold, 10, 18)]));
      expect(o.has(ZakatIssueCode.missingGoldPrice), isTrue);
      expect(o.status, ZakatStatus.incomplete);
      expect(line(o, 'metal:m1').note, LineNote.unvalued);
    });

    test('an empty goal or a paid-off debt adds no line', () {
      final ZakatOutcome o = run(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        goals: <Goal>[goal('g0', 0)],
        debts: <Debt>[debt('d0', DebtType.borrowed, 1000, paid: 1000)],
      ));
      expect(hasLine(o, 'goal:g0'), isFalse);
      expect(hasLine(o, 'debt:d0'), isFalse);
      expect(o.dueMinor, dzd(75000));
    });

    test('a metal of unknown use is counted and the result is provisional', () {
      final ZakatOutcome o = run(
          ZakatSources(
              metals: <MetalHolding>[holding('m1', Metal.gold, 100, 18)]),
          settings: ZakatSettings(
              hawlStart: start,
              goldPerPureGramMinor: dzd(36000),
              priceCurrency: 'DZD'));
      expect(o.has(ZakatIssueCode.metalUseUnspecified), isTrue);
      expect(o.status, ZakatStatus.provisional);
      expect(line(o, 'metal:m1').valueMinor, dzd(2700000));
    });
  });

  group('nothing is counted twice', () {
    test('goal savings are taken as inside the wallets unless marked outside',
        () {
      final ZakatSources src = ZakatSources(
          wallets: <Wallet>[general(3000000)], goals: <Goal>[goal('g1', 500000)]);
      final ZakatOutcome inside = run(src);
      expect(line(inside, 'goal:g1').note, LineNote.insideWallets);
      expect(line(inside, 'goal:g1').counted, isFalse);
      expect(inside.baseMinor, dzd(3000000));

      final ZakatOutcome outside = run(src,
          settings: ZakatSettings(
              hawlStart: start, goalsHeldOutside: const <String>{'g1'}));
      expect(line(outside, 'goal:g1').counted, isTrue);
      expect(outside.baseMinor, dzd(3500000));
    });

    test('a project already moved into a goal is skipped', () {
      final ZakatAssembly a = assemble(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        goals: <Goal>[goal('p1', 500000)],
        projects: <Project>[
          Project(
              id: 'p1',
              name: 'p1',
              target: Money(dzd(1000000), 'DZD'),
              saved: Money(dzd(500000), 'DZD'),
              horizon: ProjectHorizon.mid,
              createdAt: created),
        ],
      ));
      expect(a.zakatCase.cash.where((ZakatCash c) => c.key.endsWith('p1')).length,
          1);
      expect(a.notes.single.code, AssemblyNoteCode.projectIsGoal);
      expect(ZakatEngine.compute(a.zakatCase).has(ZakatIssueCode.duplicateSource),
          isFalse);
    });

    test('the older metals amount is left out once holdings are registered',
        () {
      final ZakatSettings s = ZakatSettings(
        hawlStart: start,
        goldPerPureGramMinor: dzd(36000),
        priceCurrency: 'DZD',
        metalUses: const <String, MetalUse>{'m1': MetalUse.savings},
        manual: <ZakatManual>[
          ZakatManual(
              key: 'legacy:metals',
              kind: ManualKind.metal,
              currency: 'DZD',
              amountMinor: dzd(2700000)),
        ],
      );
      final ZakatAssembly a = assemble(
          ZakatSources(metals: <MetalHolding>[holding('m1', Metal.gold, 100, 18)]),
          settings: s);
      expect(a.zakatCase.manual, isEmpty);
      expect(a.notes.single.code, AssemblyNoteCode.legacyMetalsSuperseded);
      expect(ZakatEngine.compute(a.zakatCase).baseMinor, dzd(2700000));

      // Without holdings it is still counted.
      final ZakatOutcome alone = run(const ZakatSources(), settings: s);
      expect(alone.baseMinor, dzd(2700000));
    });

    test('a transfer between wallets does not change the total', () {
      final ZakatOutcome o = run(ZakatSources(
        wallets: <Wallet>[general(2000000), wallet('ccp', dzd(1000000), 'DZD')],
        moves: <WalletMove>[
          WalletMove(
              id: 'mv',
              kind: MoveKind.transfer,
              date: DateTime(2026, 3, 1),
              amount: Money(dzd(500000), 'DZD'),
              fromId: Wallet.generalId,
              toId: 'ccp',
              createdAt: created),
        ],
      ));
      expect(line(o, 'wallet:general').valueMinor, dzd(1500000));
      expect(line(o, 'wallet:ccp').valueMinor, dzd(1500000));
      expect(o.baseMinor, dzd(3000000));
      expect(o.dueMinor, dzd(75000));
    });

    test('entries dated after the zakat date are not counted', () {
      final ZakatAssembly a = assemble(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        transactions: <Transaction>[txn('late', DateTime(2026, 12, 1), 900000)],
      ));
      expect(a.zakatCase.cash.single.amountMinor, dzd(3000000));
      expect(a.notes.single.code, AssemblyNoteCode.laterEntriesIgnored);
      expect(a.notes.single.count, 1);
    });
  });

  group('currencies', () {
    const Map<String, double> rates = <String, double>{'DZD': 140, 'EUR': 0.9};

    test('a euro wallet is converted with a dated, exact quote', () {
      final ZakatAssembly a = assemble(ZakatSources(
        wallets: <Wallet>[general(0), wallet('eur', 2000000, 'EUR')],
        ratesVsUsd: rates,
        ratesAsOf: DateTime(2026, 11, 14),
      ));
      final FxQuote q = a.zakatCase.fx.single;
      expect(q.from, 'EUR');
      expect(q.to, 'DZD');
      expect(q.source, ZakatAssembler.appRatesSource);
      expect(q.asOf, DateTime(2026, 11, 14));
      final ZakatOutcome o = ZakatEngine.compute(a.zakatCase);
      expect(line(o, 'wallet:eur').valueMinor,
          q.convert(2000000, RoundingPolicy.halfUp));
      expect(line(o, 'wallet:eur').valueMinor, closeTo(dzd(3111111), 100));
      expect(o.fxUsed.single.from, 'EUR');
    });

    test('a currency without a rate blocks the amount instead of guessing', () {
      final ZakatOutcome o = run(ZakatSources(
        wallets: <Wallet>[general(3000000), wallet('gbp', 50000, 'GBP')],
        ratesVsUsd: rates,
      ));
      expect(o.has(ZakatIssueCode.missingRate), isTrue);
      expect(o.status, ZakatStatus.incomplete);
    });

    test('a market metal price in euros is converted to dinars', () {
      final ZakatAssembly a = assemble(
        ZakatSources(
          metals: <MetalHolding>[holding('m1', Metal.gold, 10, 24)],
          metalPrices: const <Metal, MetalPrice>{
            Metal.gold: MetalPrice(
                perGram: 90, currency: 'EUR', source: MetalPriceSource.market),
          },
          ratesVsUsd: rates,
        ),
      );
      final MetalPriceQuote p = a.zakatCase.goldPrice!;
      expect(p.source, 'market');
      expect(p.perPureGramMinor, closeTo(dzd(14000), 1));
    });
  });

  group('nisab and hawl (Maliki)', () {
    test('money received during the hawl starts its own hawl', () {
      final ZakatOutcome o = run(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        transactions: <Transaction>[txn('in', DateTime(2026, 5, 1), 500000)],
      ));
      expect(line(o, 'acquired-during-hawl').valueMinor, -dzd(500000));
      expect(o.baseMinor, dzd(3000000));
      expect(o.dueMinor, dzd(75000));
    });

    test('dropping below nisab during the hawl means nothing is due yet', () {
      final ZakatOutcome o = run(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        transactions: <Transaction>[
          txn('out', DateTime(2026, 3, 1), 1000000, income: false),
          txn('in', DateTime(2026, 4, 1), 1000000),
        ],
      ));
      expect(o.nisabMet, isFalse);
      expect(o.dueMinor, 0);
    });

    test('the wallet history follows each day with entries', () {
      final ZakatAssembly a = assemble(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        transactions: <Transaction>[
          txn('a', DateTime(2025, 10, 1), 100000), // before the hawl
          txn('b', DateTime(2026, 2, 1), 200000, income: false),
          txn('c', DateTime(2026, 2, 1), 50000),
        ],
      ));
      final List<BalancePoint> h = a.zakatCase.cashHistory!;
      expect(h.map((BalancePoint p) => p.at),
          <DateTime>[start, DateTime(2026, 2, 1)]);
      expect(h.map((BalancePoint p) => p.totalMinor),
          <int>[dzd(3100000), dzd(2950000)]);
    });

    test('before the hawl ends the amount is only an estimate', () {
      final ZakatOutcome o = run(ZakatSources(wallets: <Wallet>[general(3000000)]),
          settings: ZakatSettings(hawlStart: DateTime(2026, 6, 1)));
      expect(o.has(ZakatIssueCode.beforeHawlEnd), isTrue);
      expect(o.obligatoryNow, isFalse);
    });
  });

  group('debts', () {
    test('only debts due by the zakat date are deducted', () {
      final ZakatOutcome o = run(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        debts: <Debt>[
          debt('due', DebtType.borrowed, 100000, due: DateTime(2026, 10, 1)),
          debt('open', DebtType.borrowed, 50000),
          debt('later', DebtType.borrowed, 200000, due: DateTime(2027, 6, 1)),
        ],
      ));
      expect(line(o, 'debt:due').counted, isTrue);
      expect(line(o, 'debt:open').counted, isTrue);
      expect(line(o, 'debt:later').note, LineNote.notDeducted);
      expect(o.deductionsMinor, dzd(150000));
      expect(o.baseMinor, dzd(2850000));
    });

    test('money lent waits until received; a doubtful loan is shown apart',
        () {
      final ZakatOutcome o = run(
        ZakatSources(
          wallets: <Wallet>[general(3000000)],
          debts: <Debt>[
            debt('lent', DebtType.lent, 400000, paid: 100000),
            debt('lost', DebtType.lent, 80000),
          ],
        ),
        settings:
            ZakatSettings(hawlStart: start, doubtfulReceivables: const <String>{'lost'}),
      );
      expect(line(o, 'debt:lent').note, LineNote.untilReceived);
      expect(line(o, 'debt:lent').originalMinor, dzd(300000));
      expect(line(o, 'debt:lost').note, LineNote.doubtfulReceivable);
      expect(o.baseMinor, dzd(3000000));
    });

    test('a debt dated after the zakat date is left out', () {
      final ZakatAssembly a = assemble(ZakatSources(
        wallets: <Wallet>[general(3000000)],
        debts: <Debt>[
          debt('new', DebtType.borrowed, 100000, on: DateTime(2026, 12, 1)),
        ],
      ));
      expect(a.zakatCase.debts, isEmpty);
      expect(a.notes.single.code, AssemblyNoteCode.laterDebtIgnored);
    });
  });

  group('gold and silver', () {
    final ZakatSettings prices = ZakatSettings(
      hawlStart: start,
      goldPerPureGramMinor: dzd(36000),
      silverPerPureGramMinor: dzd(200),
      priceCurrency: 'DZD',
      metalUses: const <String, MetalUse>{
        'ring': MetalUse.adornment,
        'bar': MetalUse.savings,
        'coins': MetalUse.savings,
      },
    );

    test('saved gold and silver are valued by their pure weight', () {
      final ZakatOutcome o = run(
        ZakatSources(metals: <MetalHolding>[
          holding('bar', Metal.gold, 100, 18), // 75 g pure
          holding('coins', Metal.silver, 1000, 925), // 925 g pure
        ]),
        settings: prices,
      );
      expect(line(o, 'metal:bar').valueMinor, dzd(2700000));
      expect(line(o, 'metal:coins').valueMinor, dzd(185000));
      expect(o.baseMinor, dzd(2885000));
      expect(o.dueMinor, dzd(72125));
    });

    test('worn jewellery is exempt (Maliki)', () {
      final ZakatOutcome o = run(
        ZakatSources(
            metals: <MetalHolding>[holding('ring', Metal.gold, 100, 18)]),
        settings: prices,
      );
      expect(line(o, 'metal:ring').note, LineNote.adornmentExempt);
      expect(o.baseMinor, 0);
    });

    test('the price entered for zakat wins over the market price', () {
      final ZakatAssembly a = assemble(
        ZakatSources(
          metals: <MetalHolding>[holding('bar', Metal.gold, 10, 24)],
          metalPrices: const <Metal, MetalPrice>{
            Metal.gold: MetalPrice(
                perGram: 20000, currency: 'DZD', source: MetalPriceSource.market),
          },
        ),
        settings: prices,
      );
      expect(a.zakatCase.goldPrice!.source, 'user');
      expect(a.zakatCase.goldPrice!.perPureGramMinor, dzd(36000));
    });

    test("the app's own local price is used when none was entered", () {
      final ZakatAssembly a = assemble(ZakatSources(
        metals: <MetalHolding>[holding('bar', Metal.gold, 10, 24)],
        metalPrices: const <Metal, MetalPrice>{
          Metal.gold: MetalPrice(
              perGram: 35500, currency: 'DZD', source: MetalPriceSource.mine),
        },
      ));
      expect(a.zakatCase.goldPrice!.source, 'mine');
      expect(a.zakatCase.goldPrice!.perPureGramMinor, dzd(35500));
    });

    test('platinum is not zakatable unless held for trade', () {
      final ZakatOutcome o = run(ZakatSources(
        metals: <MetalHolding>[holding('pt', Metal.platinum, 10, 950)],
        metalPrices: const <Metal, MetalPrice>{
          Metal.platinum: MetalPrice(
              perGram: 9000, currency: 'DZD', source: MetalPriceSource.mine),
        },
      ));
      expect(line(o, 'metal:pt').note, LineNote.notZakatableMetal);
      expect(o.baseMinor, 0);
    });
  });

  group('the Algerian engine stands alone', () {
    test('only Algeria is enabled; a Saudi market resolves to nothing', () {
      expect(ZakatMarkets.enabled.map((p) => p.code), <String>['DZ']);
      expect(ZakatMarkets.byCountry('SA'), isNull);
      expect(ZakatMarkets.resolve(ZakatSettings.empty, 'SAR'), isNull);
      expect(
          ZakatMarkets.resolve(const ZakatSettings(country: 'SA'), 'DZD'), isNull);
      expect(ZakatMarkets.resolve(ZakatSettings.empty, 'DZD'),
          same(algeriaZakatProfile));
      expect(ZakatMarkets.resolve(const ZakatSettings(country: 'DZ'), 'EUR'),
          same(algeriaZakatProfile));
    });

    test('the approved Maliki rules are used exactly as set in phase 1', () {
      expect(ZakatMarkets.rulesFor(algeriaZakatProfile, ZakatSettings.empty),
          same(maliki));
      expect(maliki.version, 'dz-2026.11-maliki');
      expect(maliki.approved, isTrue);
      expect(maliki.nisabBasis, NisabBasis.official);
      expect(maliki.acquiredWealth, AcquiredWealthPolicy.minimumBalance);
      expect(maliki.nisabContinuity, NisabContinuity.throughout);
      expect(maliki.wornJewelry, WornJewelryPolicy.exempt);
      expect(maliki.receivables, ReceivablesPolicy.onReceipt);
      expect(maliki.debtDeduction, DebtDeductionPolicy.dueByZakatDate);
      expect(maliki.rateBasisPoints, 250);
    });

    test('another school is a preset, not approved, so results stay provisional',
        () {
      final ZakatSettings hanafi =
          ZakatSettings(hawlStart: start, school: ZakatSchool.hanafi);
      final ZakatRules r = ZakatMarkets.rulesFor(algeriaZakatProfile, hanafi);
      expect(r.approved, isFalse);
      expect(r.school, ZakatSchool.hanafi);
      expect(r.nisabBasis, NisabBasis.official);
      final ZakatOutcome o = run(
          ZakatSources(wallets: <Wallet>[general(3000000)]),
          settings: hanafi);
      expect(o.status, ZakatStatus.provisional);
      expect(o.has(ZakatIssueCode.rulesNotApproved), isTrue);
    });

    test('the zakat currency is the dinar whatever the base currency', () {
      final ZakatOutcome o = run(const ZakatSources());
      expect(o.currency, 'DZD');
      expect(ZakatMoney.decimalsOf('DZD'), 2);
    });
  });
}
