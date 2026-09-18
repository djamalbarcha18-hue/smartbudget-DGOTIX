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
}
