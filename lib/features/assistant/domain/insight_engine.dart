import 'package:smartbudget/features/financial_health/domain/health_calculator.dart';

/// Visual/semantic tone of an insight (drives colour + icon only).
enum InsightTone { positive, warning, info }

/// The kind of insight, so the presentation layer can localise the message.
///
/// IMPORTANT (governance): every key maps to a state ALREADY computed by an
/// existing engine (finance summary, health bands, goal tiers, debt status,
/// zakat obligation) or to a plain arithmetic fact (net sign, largest category).
/// The engine invents NO new financial rule and NO new threshold — it only
/// surfaces and phrases what the domain calculators already decided.
enum InsightKey {
  netSurplus,
  netDeficit,
  savingsRate,
  topExpenseCategory,
  healthExcellent,
  healthVeryGood,
  healthGood,
  healthFair,
  healthNeedsWork,
  goalsAchieved,
  goalsUrgent,
  debtsOverdue,
  debtsOwedToMe,
  debtsOwedByMe,
  zakatDue,
}

/// A single rule-based insight: a key + tone + the numeric/text params the
/// message needs. Money is carried as minor units + currency; formatting and
/// translation happen in the presentation layer.
class Insight {
  const Insight(
    this.key,
    this.tone, {
    this.amountMinor,
    this.currency,
    this.rate,
    this.category,
    this.count,
  });

  final InsightKey key;
  final InsightTone tone;
  final int? amountMinor;
  final String? currency;
  final double? rate;
  final String? category;
  final int? count;
}

/// Snapshot of already-computed figures the engine phrases into insights.
class InsightInput {
  const InsightInput({
    required this.currency,
    required this.transactionCount,
    required this.netMinor,
    required this.savingsRate,
    this.hasHealth = false,
    this.healthStatus,
    this.topExpenseCategory,
    this.topExpenseMinor = 0,
    this.achievedGoals = 0,
    this.urgentGoals = 0,
    this.overdueDebts = 0,
    this.owedToMeMinor = 0,
    this.owedByMeMinor = 0,
    this.zakatDue = false,
    this.zakatDueMinor = 0,
  });

  final String currency;
  final int transactionCount;
  final int netMinor;
  final double savingsRate;
  final bool hasHealth;
  final HealthStatus? healthStatus;
  final String? topExpenseCategory;
  final int topExpenseMinor;
  final int achievedGoals;
  final int urgentGoals;
  final int overdueDebts;
  final int owedToMeMinor;
  final int owedByMeMinor;
  final bool zakatDue;
  final int zakatDueMinor;
}

/// Produces an ordered list of rule-based insights from existing figures.
///
/// Ordering: warnings first (things to act on), then neutral facts, then
/// positive reinforcement — a calm, scannable priority for the user.
abstract final class InsightEngine {
  static List<Insight> generate(InsightInput i) {
    if (i.transactionCount == 0) return const <Insight>[];

    final List<Insight> warnings = <Insight>[];
    final List<Insight> info = <Insight>[];
    final List<Insight> positive = <Insight>[];

    // Net position (plain fact: sign of income - expense).
    if (i.netMinor < 0) {
      warnings.add(Insight(InsightKey.netDeficit, InsightTone.warning,
          amountMinor: -i.netMinor, currency: i.currency));
    } else if (i.netMinor > 0) {
      positive.add(Insight(InsightKey.netSurplus, InsightTone.positive,
          amountMinor: i.netMinor, currency: i.currency));
    }

    // Overdue debts (existing DebtStatus.overdue).
    if (i.overdueDebts > 0) {
      warnings.add(Insight(InsightKey.debtsOverdue, InsightTone.warning,
          count: i.overdueDebts));
    }

    // Goals nearing their deadline (existing GoalUrgency.urgent).
    if (i.urgentGoals > 0) {
      warnings.add(Insight(InsightKey.goalsUrgent, InsightTone.warning,
          count: i.urgentGoals));
    }

    // Financial-health band (existing HealthStatus). Tone follows the band the
    // health engine already assigned — no new threshold introduced here.
    if (i.hasHealth && i.healthStatus != null) {
      info.add(_healthInsight(i.healthStatus!));
    }

    // Savings rate — reported as a neutral fact (no good/bad judgement, so no
    // invented benchmark).
    info.add(Insight(InsightKey.savingsRate, InsightTone.info,
        rate: i.savingsRate));

    // Largest expense category (plain arithmetic: max of category totals).
    if (i.topExpenseCategory != null && i.topExpenseMinor > 0) {
      info.add(Insight(InsightKey.topExpenseCategory, InsightTone.info,
          category: i.topExpenseCategory,
          amountMinor: i.topExpenseMinor,
          currency: i.currency));
    }

    // Debt net position (existing DebtSummary).
    if (i.owedToMeMinor > 0) {
      info.add(Insight(InsightKey.debtsOwedToMe, InsightTone.info,
          amountMinor: i.owedToMeMinor, currency: i.currency));
    }
    if (i.owedByMeMinor > 0) {
      info.add(Insight(InsightKey.debtsOwedByMe, InsightTone.info,
          amountMinor: i.owedByMeMinor, currency: i.currency));
    }

    // Zakat obligation (existing ZakatResult.obligatory — only ever true once
    // the user has entered a nisab price).
    if (i.zakatDue) {
      info.add(Insight(InsightKey.zakatDue, InsightTone.info,
          amountMinor: i.zakatDueMinor, currency: i.currency));
    }

    // Achieved goals (existing GoalStatus.completed).
    if (i.achievedGoals > 0) {
      positive.add(Insight(InsightKey.goalsAchieved, InsightTone.positive,
          count: i.achievedGoals));
    }

    return <Insight>[...warnings, ...info, ...positive];
  }

  static Insight _healthInsight(HealthStatus s) => switch (s) {
        HealthStatus.excellent =>
          const Insight(InsightKey.healthExcellent, InsightTone.positive),
        HealthStatus.veryGood =>
          const Insight(InsightKey.healthVeryGood, InsightTone.positive),
        HealthStatus.good =>
          const Insight(InsightKey.healthGood, InsightTone.info),
        HealthStatus.fair =>
          const Insight(InsightKey.healthFair, InsightTone.warning),
        HealthStatus.needsWork =>
          const Insight(InsightKey.healthNeedsWork, InsightTone.warning),
      };
}
