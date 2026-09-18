import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// A bundle of demo transactions + budget targets for one year.
class SampleDataSet {
  const SampleDataSet({required this.transactions, required this.budgets});
  final List<Transaction> transactions;
  final List<BudgetTarget> budgets;
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

    for (int m = 1; m <= 12; m++) {
      // Income.
      txns.add(t('salary', m, 1, TransactionType.income, 'راتب أساسي', 3200,
          'راتب شهري'));
      txns.add(t('freelance', m, 18, TransactionType.income, 'عمل حر',
          350 + m * 25, 'مشروع مستقل'));

      // Expenses.
      txns.add(t('food', m, 3, TransactionType.expense, 'الطعام', 520 + m * 10,
          'بقالة', payment: 'بطاقة بنكية'));
      txns.add(t('rest', m, 7, TransactionType.expense, 'المطاعم',
          180 + (m % 4) * 30, 'مطعم', payment: 'بطاقة ائتمان'));
      txns.add(t('transport', m, 9, TransactionType.expense, 'النقل', 140,
          'مواصلات', payment: 'نقداً'));
      txns.add(t('bills', m, 11, TransactionType.expense, 'الفواتير',
          260 + (m % 3) * 20, 'كهرباء وماء', payment: 'تحويل بنكي فوري'));
      txns.add(t('fuel', m, 14, TransactionType.expense, 'الوقود', 150, 'وقود',
          payment: 'بطاقة بنكية'));
      txns.add(t('shopping', m, 20, TransactionType.expense, 'التسوق',
          120 + m * 15, 'تسوّق', payment: 'بطاقة بنكية'));
      if (m.isEven) {
        txns.add(t('health', m, 22, TransactionType.expense, 'الصحة', 95,
            'صيدلية', payment: 'نقداً'));
      }
      txns.add(t('fun', m, 25, TransactionType.expense, 'الترفيه',
          110 + (m % 5) * 20, 'ترفيه', payment: 'محفظة إلكترونية'));

      // Planned budgets (feed planned-vs-actual).
      budgets.add(b('food', m, 'الطعام', 600));
      budgets.add(b('rest', m, 'المطاعم', 250));
      budgets.add(b('transport', m, 'النقل', 160));
      budgets.add(b('bills', m, 'الفواتير', 300));
      budgets.add(b('fuel', m, 'الوقود', 180));
      budgets.add(b('shopping', m, 'التسوق', 250));
    }

    return SampleDataSet(transactions: txns, budgets: budgets);
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
