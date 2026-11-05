import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/domain/debt_calculator.dart';

const String usd = 'USD';

Debt _debt({
  required DebtType type,
  required double original,
  double paid = 0,
  DateTime? dueDate,
}) {
  return Debt(
    id: 'd-${original.hashCode}-${paid.hashCode}',
    party: 'Someone',
    type: type,
    original: Money.fromDouble(original, usd),
    paid: Money.fromDouble(paid, usd),
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final DateTime now = DateTime(2026, 6, 1);

  group('DebtCalculator.remaining', () {
    test('remaining = max(0, original - paid)', () {
      expect(
        DebtCalculator.remaining(
            _debt(type: DebtType.borrowed, original: 1000, paid: 300)),
        Money.fromDouble(700, usd),
      );
      // Overpaid never goes negative.
      expect(
        DebtCalculator.remaining(
            _debt(type: DebtType.borrowed, original: 100, paid: 150)),
        Money.fromDouble(0, usd),
      );
    });
  });

  group('DebtCalculator.status', () {
    test('paid when nothing remains', () {
      expect(
        DebtCalculator.status(
            _debt(type: DebtType.lent, original: 500, paid: 500),
            now: now),
        DebtStatus.paid,
      );
    });

    test('active when nothing paid and not overdue', () {
      expect(
        DebtCalculator.status(_debt(type: DebtType.lent, original: 500),
            now: now),
        DebtStatus.active,
      );
    });

    test('partiallyPaid when some paid and not overdue', () {
      expect(
        DebtCalculator.status(
            _debt(type: DebtType.lent, original: 500, paid: 200),
            now: now),
        DebtStatus.partiallyPaid,
      );
    });

    test('overdue when past due date and still owed', () {
      expect(
        DebtCalculator.status(
          _debt(
            type: DebtType.borrowed,
            original: 500,
            paid: 100,
            dueDate: DateTime(2026, 5, 1),
          ),
          now: now,
        ),
        DebtStatus.overdue,
      );
    });
  });

  group('DebtCalculator.summary', () {
    test('nets outstanding lent vs borrowed, ignores settled', () {
      final List<Debt> debts = <Debt>[
        _debt(type: DebtType.lent, original: 1000, paid: 200), // remaining 800
        _debt(type: DebtType.borrowed, original: 500), // remaining 500
        _debt(type: DebtType.borrowed, original: 300, paid: 300), // settled
      ];
      final DebtSummary s = DebtCalculator.summary(debts, usd);
      expect(s.owedToMe, Money.fromDouble(800, usd));
      expect(s.owedByMe, Money.fromDouble(500, usd));
      expect(s.net, Money.fromDouble(300, usd));
      expect(s.openCount, 2);
    });
  });

  group('debts in another currency', () {
    // Units of each currency per 1 USD, as the app's rates are.
    const Map<String, double> rates = <String, double>{
      'USD': 1.0,
      'EUR': 0.9,
      'DZD': 135.0,
    };

    Debt debtIn(String currency, DebtType type, double original,
        {double paid = 0}) {
      return Debt(
        id: 'd-$currency-${type.name}-$original-$paid',
        party: 'Friend',
        type: type,
        original: Money.fromDouble(original, currency),
        paid: Money.fromDouble(paid, currency),
        createdAt: DateTime(2026, 1, 1),
      );
    }

    test('is counted at the rate of the day, in the base currency', () {
      // 100 EUR / 0.9 * 135 = 15,000 DZD.
      final DebtSummary s = DebtCalculator.summary(
        <Debt>[debtIn('EUR', DebtType.lent, 100)],
        'DZD',
        ratesVsUsd: rates,
      );
      expect(s.owedToMe, Money.fromDouble(15000, 'DZD'));
      expect(s.convertedCount, 1);
      expect(s.missingRateCodes, isEmpty);
    });

    test('what is left is converted, not the original', () {
      // 200 EUR with 50 paid: 150 EUR left = 22,500 DZD.
      final DebtSummary s = DebtCalculator.summary(
        <Debt>[debtIn('EUR', DebtType.borrowed, 200, paid: 50)],
        'DZD',
        ratesVsUsd: rates,
      );
      expect(s.owedByMe, Money.fromDouble(22500, 'DZD'));
    });

    test('adds to debts already in the base currency', () {
      final DebtSummary s = DebtCalculator.summary(
        <Debt>[
          debtIn('DZD', DebtType.lent, 10000),
          debtIn('EUR', DebtType.lent, 100), // 15,000 DZD
          debtIn('USD', DebtType.borrowed, 50), // 6,750 DZD
        ],
        'DZD',
        ratesVsUsd: rates,
      );
      expect(s.owedToMe, Money.fromDouble(25000, 'DZD'));
      expect(s.owedByMe, Money.fromDouble(6750, 'DZD'));
      expect(s.net, Money.fromDouble(18250, 'DZD'));
      expect(s.openCount, 3);
      expect(s.convertedCount, 2);
    });

    test('with no rate for its currency it is left out and named, not dropped',
        () {
      final DebtSummary s = DebtCalculator.summary(
        <Debt>[
          debtIn('DZD', DebtType.lent, 1000),
          debtIn('GBP', DebtType.lent, 100),
          debtIn('GBP', DebtType.borrowed, 30),
          debtIn('JPY', DebtType.lent, 5000),
        ],
        'DZD',
        ratesVsUsd: rates,
      );
      expect(s.owedToMe, Money.fromDouble(1000, 'DZD'));
      expect(s.missingRateCodes, <String>['GBP', 'JPY']);
      expect(s.openCount, 4, reason: 'every open debt is still counted');
      expect(s.convertedCount, 0);
    });

    test('a settled debt in another currency needs no rate and is not counted',
        () {
      final DebtSummary s = DebtCalculator.summary(
        <Debt>[debtIn('GBP', DebtType.lent, 100, paid: 100)],
        'DZD',
        ratesVsUsd: rates,
      );
      expect(s.openCount, 0);
      expect(s.missingRateCodes, isEmpty);
      expect(s.convertedCount, 0);
    });

    test('a debt in the base currency never needs a rate', () {
      final DebtSummary s = DebtCalculator.summary(
        <Debt>[debtIn('DZD', DebtType.lent, 700)],
        'DZD',
      );
      expect(s.owedToMe, Money.fromDouble(700, 'DZD'));
      expect(s.convertedCount, 0);
      expect(s.missingRateCodes, isEmpty);
    });

    test('inBase: same currency is itself; no rate is null', () {
      final Money eur = Money.fromDouble(10, 'EUR');
      expect(DebtCalculator.inBase(eur, 'EUR', const <String, double>{}), eur);
      expect(
          DebtCalculator.inBase(eur, 'DZD', const <String, double>{}), isNull);
      expect(DebtCalculator.inBase(eur, 'DZD', rates),
          Money.fromDouble(1500, 'DZD'));
    });

    test('keeps its own currency through a save and a reload', () {
      final Debt d = debtIn('EUR', DebtType.lent, 123.45, paid: 20);
      final Debt back = Debt.fromJson(d.toJson());
      expect(back.original, d.original);
      expect(back.paid, d.paid);
      expect(back.original.currencyCode, 'EUR');
    });
  });

  group('totals one line per currency', () {
    Debt d(String currency, DebtType type, double original, {double paid = 0}) {
      return Debt(
        id: 'p-$currency-${type.name}-$original-$paid',
        party: 'Friend',
        type: type,
        original: Money.fromDouble(original, currency),
        paid: Money.fromDouble(paid, currency),
        createdAt: DateTime(2026, 1, 1),
      );
    }

    test('adds each currency on its own and converts nothing', () {
      final List<CurrencyPosition> p = DebtCalculator.byCurrency(<Debt>[
        d('EUR', DebtType.lent, 100),
        d('EUR', DebtType.lent, 50, paid: 20), // 30 left
        d('EUR', DebtType.borrowed, 40),
        d('USD', DebtType.borrowed, 10),
      ], 'DZD');
      final CurrencyPosition eur = p.firstWhere((x) => x.code == 'EUR');
      expect(eur.owedToMe, Money.fromDouble(130, 'EUR'));
      expect(eur.owedByMe, Money.fromDouble(40, 'EUR'));
      expect(eur.net, Money.fromDouble(90, 'EUR'));
      expect(eur.openCount, 3);
      final CurrencyPosition usd = p.firstWhere((x) => x.code == 'USD');
      expect(usd.owedToMe, Money.fromDouble(0, 'USD'));
      expect(usd.net, Money.fromDouble(-10, 'USD'));
    });

    test('the base currency comes first, then the others by code', () {
      final List<CurrencyPosition> p = DebtCalculator.byCurrency(<Debt>[
        d('USD', DebtType.lent, 1),
        d('GBP', DebtType.lent, 1),
        d('DZD', DebtType.lent, 1),
        d('EUR', DebtType.lent, 1),
      ], 'DZD');
      expect(p.map((x) => x.code), <String>['DZD', 'EUR', 'GBP', 'USD']);
    });

    test('a settled debt, or a currency with nothing open, has no line', () {
      final List<CurrencyPosition> p = DebtCalculator.byCurrency(<Debt>[
        d('EUR', DebtType.lent, 100, paid: 100),
        d('USD', DebtType.lent, 5),
      ], 'DZD');
      expect(p.map((x) => x.code), <String>['USD']);
      expect(DebtCalculator.byCurrency(const <Debt>[], 'DZD'), isEmpty);
    });

    test('needs no exchange rate, so no currency is ever left out', () {
      final List<CurrencyPosition> p = DebtCalculator.byCurrency(<Debt>[
        d('XXX', DebtType.lent, 7),
      ], 'DZD');
      expect(p.single.code, 'XXX');
      expect(p.single.owedToMe, Money.fromDouble(7, 'XXX'));
    });
  });
}
