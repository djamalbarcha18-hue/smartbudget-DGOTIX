import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/budget/domain/budget_target.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// What switching the base (template) currency from [from] to [to] hides.
///
/// Records keep the currency they were created in, and totals only count the
/// base currency, so anything counted under [from] but not under [to] drops
/// out of totals and reports — except transactions the app values in [to] by
/// itself once its rates are trusted (see `convertible`). Nothing is deleted:
/// switching back shows it again. Used to warn before the switch.
class BaseCurrencyImpact {
  const BaseCurrencyImpact({
    this.transactions = 0,
    this.budgets = 0,
    this.goals = 0,
    this.debts = 0,
    this.projects = 0,
    this.seasons = 0,
    this.darets = 0,
  });

  final int transactions;
  final int budgets;
  final int goals;
  final int debts;
  final int projects;
  final int seasons;
  final int darets;

  int get total =>
      transactions + budgets + goals + debts + projects + seasons + darets;

  bool get isEmpty => total == 0;

  static BaseCurrencyImpact of({
    required String from,
    required String to,
    Iterable<Transaction> transactions = const <Transaction>[],
    Iterable<BudgetTarget> budgets = const <BudgetTarget>[],
    Iterable<Goal> goals = const <Goal>[],
    Iterable<Debt> debts = const <Debt>[],
    Iterable<Project> projects = const <Project>[],
    Iterable<SeasonPlan> seasons = const <SeasonPlan>[],
    Iterable<Daret> darets = const <Daret>[],
    bool Function(String code)? convertible,
  }) {
    if (from == to) return const BaseCurrencyImpact();
    bool hidden(Money m) => m.currencyCode == from;
    // A transaction the app can value in [to] on its own stays in totals.
    bool converted(Transaction t) =>
        convertible != null &&
        convertible(t.amount.currencyCode) &&
        convertible(to);
    return BaseCurrencyImpact(
      transactions: transactions
          .where((Transaction t) =>
              t.inCurrency(from) != null &&
              t.inCurrency(to) == null &&
              !converted(t))
          .length,
      budgets: budgets.where((BudgetTarget b) => hidden(b.planned)).length,
      goals: goals.where((Goal g) => hidden(g.target)).length,
      debts: debts.where((Debt d) => hidden(d.original)).length,
      projects: projects.where((Project p) => hidden(p.target)).length,
      seasons: seasons.where((SeasonPlan s) => hidden(s.budget)).length,
      darets: darets.where((Daret d) => hidden(d.contribution)).length,
    );
  }
}
