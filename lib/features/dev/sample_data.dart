import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// A bundle of demo transactions + budget targets + goals for one year.
class SampleDataSet {
  const SampleDataSet({
    required this.transactions,
    required this.budgets,
    required this.goals,
  });
  final List<Transaction> transactions;
  final List<BudgetTarget> budgets;
  final List<Goal> goals;
}

/// Deterministic demo data for testing the template (default year 2026).
///
/// Amounts are in the user's base [currency]. Ids are stable, so importing more
/// than once is idempotent (the repositories merge by id / by
/// year+month+category and skip duplicates). All categories are real
/// [Catalog] expense/income categories so they render everywhere.
abstract final class SampleData {
  static SampleDataSet build({required String currency, int year = 2026}) {
    final List<Transaction> txns = <Transaction>[];
    final List<BudgetTarget> budgets = <BudgetTarget>[];
    final DateTime created = DateTime(year, 1, 1);

    Transaction t(
      String id,
      int month,
      int day,
      TransactionType type,
      String category,
      double amount,
      String description, {
      String? payment,
    }) =>
        Transaction(
          id: 'smpl-$year-${_two(month)}-$id',
          date: DateTime(year, month, day),
          type: type,
          category: category,
          amount: Money.fromDouble(amount, currency),
          description: description,
          paymentMethod: payment,
          createdAt: created,
        );

    BudgetTarget b(String id, int month, String category, double amount) =>
        BudgetTarget(
          id: 'smplb-$year-${_two(month)}-$id',
          year: year,
          month: month,
          category: category,
          planned: Money.fromDouble(amount, currency),
          createdAt: created,
        );

    // Per-month multipliers so income, expenses and net differ clearly each
    // month (June & December income spikes; seasonal expense swings).
    const List<double> incomeFactor = <double>[
      1.00, 0.92, 1.08, 1.00, 1.18, 1.55, 0.95, 1.05, 1.12, 1.00, 1.10, 1.60,
    ];
    const List<double> expenseFactor = <double>[
      1.30, 0.88, 1.00, 1.10, 0.98, 1.22, 1.42, 1.35, 1.02, 0.95, 1.08, 1.50,
    ];

    double round2(double v) => (v * 100).roundToDouble() / 100;

    for (int m = 1; m <= 12; m++) {
      final double fi = incomeFactor[m - 1];
      final double fe = expenseFactor[m - 1];

      // Income.
      txns.add(t('salary', m, 1, TransactionType.income, 'راتب أساسي',
          round2(3000 * fi), 'راتب شهري'));
      txns.add(t('freelance', m, 18, TransactionType.income, 'عمل حر',
          round2(600 * fi), 'مشروع مستقل'));

      // Expenses.
      txns.add(t('food', m, 3, TransactionType.expense, 'الطعام',
          round2(520 * fe), 'بقالة', payment: 'بطاقة بنكية'));
      txns.add(t('rest', m, 7, TransactionType.expense, 'المطاعم',
          round2(180 * fe), 'مطعم', payment: 'بطاقة ائتمان'));
      txns.add(t('transport', m, 9, TransactionType.expense, 'النقل',
          round2(140 * fe), 'مواصلات', payment: 'نقداً'));
      txns.add(t('bills', m, 11, TransactionType.expense, 'الفواتير',
          round2(260 * fe), 'كهرباء وماء', payment: 'تحويل بنكي فوري'));
      txns.add(t('fuel', m, 14, TransactionType.expense, 'الوقود',
          round2(150 * fe), 'وقود', payment: 'بطاقة بنكية'));
      txns.add(t('shopping', m, 20, TransactionType.expense, 'التسوق',
          round2(200 * fe), 'تسوّق', payment: 'بطاقة بنكية'));
      if (m.isEven) {
        txns.add(t('health', m, 22, TransactionType.expense, 'الصحة',
            round2(120 * fe), 'صيدلية', payment: 'نقداً'));
      }
      txns.add(t('fun', m, 25, TransactionType.expense, 'الترفيه',
          round2(130 * fe), 'ترفيه', payment: 'محفظة إلكترونية'));

      // Planned budgets (feed planned-vs-actual).
      budgets.add(b('food', m, 'الطعام', 600));
      budgets.add(b('rest', m, 'المطاعم', 250));
      budgets.add(b('transport', m, 'النقل', 160));
      budgets.add(b('bills', m, 'الفواتير', 300));
      budgets.add(b('fuel', m, 'الوقود', 180));
      budgets.add(b('shopping', m, 'التسوق', 250));
    }

    // A few savings goals so the dashboard's goals card fills in too.
    final List<Goal> goals = <Goal>[
      Goal(
        id: 'smpl-goal-emergency',
        name: 'صندوق الطوارئ',
        target: Money.fromDouble(10000, currency),
        saved: Money.fromDouble(6500, currency),
        deadline: DateTime(year, 12, 31),
        createdAt: created,
      ),
      Goal(
        id: 'smpl-goal-car',
        name: 'شراء سيارة',
        target: Money.fromDouble(25000, currency),
        saved: Money.fromDouble(9000, currency),
        deadline: DateTime(year + 1, 6, 30),
        createdAt: created,
      ),
      Goal(
        id: 'smpl-goal-trip',
        name: 'إجازة العائلة',
        target: Money.fromDouble(4000, currency),
        saved: Money.fromDouble(2500, currency),
        deadline: DateTime(year, 8, 15),
        createdAt: created,
      ),
    ];

    return SampleDataSet(
        transactions: txns, budgets: budgets, goals: goals);
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
