import 'dart:math' as math;

/// Overall status bands on the 0..100 SB Financial-Health Score (SB-FHS).
enum HealthStatus { excellent, veryGood, good, fair, needsWork }

HealthStatus statusOf(double score) {
  if (score >= 85) return HealthStatus.excellent;
  if (score >= 70) return HealthStatus.veryGood;
  if (score >= 55) return HealthStatus.good;
  if (score >= 40) return HealthStatus.fair;
  return HealthStatus.needsWork;
}

/// The pillars of the model. Correlated behaviours are grouped into ONE pillar
/// (e.g. all spending signals) so the same behaviour is never counted twice.
/// Conceptually aligned with the international financial-health dimensions
/// (Spend / Save / Borrow / Plan) plus an explicit Resilience dimension.
enum HealthPillarKey {
  cashFlow, // Spend — living within means
  savings, // Save — surplus kept
  resilience, // Liquidity buffer to absorb a shock
  debt, // Borrow — debt manageability
  incomeStability, // volatility of income
  planning, // Plan — goals
}

enum HealthTrend { improving, stable, declining, unknown }

/// A critical, interpretable risk that caps the overall score.
enum RiskKind {
  negativeCashFlow,
  spendingExceedsIncome,
  highDebtService,
  highDebtToIncome,
  noEmergencyBuffer,
  incomeInstability,
}

class HealthRisk {
  const HealthRisk(this.kind, {this.months, this.ratio});
  final RiskKind kind;
  final double? months;
  final double? ratio;
}

/// One pillar's outcome: 0..100 score, its nominal weight, whether the data to
/// compute it existed, and how confident that computation is (0..1).
class HealthPillar {
  const HealthPillar({
    required this.key,
    required this.score,
    required this.weight,
    required this.available,
    required this.confidence,
  });
  final HealthPillarKey key;
  final double score;
  final double weight;
  final bool available;
  final double confidence;
}

/// The full, interpretable health report.
class HealthReport {
  const HealthReport({
    required this.score,
    required this.status,
    required this.confidence,
    required this.resilience,
    required this.pillars,
    required this.risks,
    required this.strengths,
    required this.weaknesses,
    required this.trend,
    required this.emergencyMonths,
    required this.hasData,
  });

  final double score; // 0..100 SB-FHS (after critical-risk caps)
  final HealthStatus status;
  final double confidence; // 0..100 Data Confidence (separate from score)
  final double resilience; // 0..100 Financial Resilience (separate lens)
  final List<HealthPillar> pillars;
  final List<HealthRisk> risks;
  final List<HealthPillarKey> strengths;
  final List<HealthPillarKey> weaknesses;
  final HealthTrend trend;
  final double? emergencyMonths; // liquid coverage in months (null = unknown)
  final bool hasData;

  static const HealthReport empty = HealthReport(
    score: 0,
    status: HealthStatus.needsWork,
    confidence: 0,
    resilience: 0,
    pillars: <HealthPillar>[],
    risks: <HealthRisk>[],
    strengths: <HealthPillarKey>[],
    weaknesses: <HealthPillarKey>[],
    trend: HealthTrend.unknown,
    emergencyMonths: null,
    hasData: false,
  );
}

/// All figures the engine needs (base-currency minor units; one year).
class HealthFacts {
  const HealthFacts({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.essentialExpenseMinor,
    required this.discretionaryExpenseMinor,
    required this.debtServiceMinor,
    required this.plannedExpenseMinor,
    required this.owedByMeMinor,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.goalsProgress,
    required this.goalsCount,
    required this.emergencySavingsMinor,
  });

  final int incomeMinor;
  final int expenseMinor;
  final int essentialExpenseMinor;
  final int discretionaryExpenseMinor;
  final int debtServiceMinor; // loan/installment outflows (year)
  final int plannedExpenseMinor; // budget target (year); 0 = not set
  final int owedByMeMinor; // outstanding liabilities (stock)
  final List<int> monthlyIncome; // 12
  final List<int> monthlyExpense; // 12
  final double goalsProgress; // 0..1 saved/target
  final int goalsCount;
  final int? emergencySavingsMinor; // null = unknown (NOT zero)
}

/// The central, pure Financial-Health engine. Pipeline:
/// facts → raw metrics → normalized metrics → pillar scores → risk analysis
/// → resilience → final SB-FHS + data confidence + interpretation.
abstract final class HealthEngine {
  // ---- Nominal pillar weights (sum = 1.00). Rationale in the docs/PR. ----
  static const Map<HealthPillarKey, double> weights = <HealthPillarKey, double>{
    HealthPillarKey.cashFlow: 0.25, // foundation: living within means
    HealthPillarKey.savings: 0.20, // surplus actually kept
    HealthPillarKey.resilience: 0.20, // survival: buffer for a shock
    HealthPillarKey.debt: 0.20, // debt manageability
    HealthPillarKey.incomeStability: 0.10, // volatility / risk modifier
    HealthPillarKey.planning: 0.05, // goals (aspirational)
  };

  static HealthReport evaluate(HealthFacts f) {
    final double income = f.incomeMinor.toDouble();
    if (income <= 0 && f.expenseMinor <= 0) return HealthReport.empty;

    final int active = _activeMonths(f);
    final double annualIncome = income;

    // ---- Raw ratios (currency-agnostic) ----
    final double savingsRate =
        income <= 0 ? -1 : (income - f.expenseMinor) / income;
    final double expenseToIncome = income <= 0 ? 2 : f.expenseMinor / income;
    final double discretionaryRatio =
        income <= 0 ? 1 : f.discretionaryExpenseMinor / income;
    final double dti = income <= 0 ? 5 : f.owedByMeMinor / annualIncome;
    final double dsr = income <= 0 ? 1 : f.debtServiceMinor / annualIncome;
    final double cv = _incomeCv(f.monthlyIncome, active);
    final double avgEssentialMonthly =
        f.essentialExpenseMinor / math.max(active, 1);
    final double? coverage = _coverageMonths(
        f.emergencySavingsMinor, avgEssentialMonthly);
    final double posMonthRatio = _positiveNetMonthRatio(f, active);

    // ---- Pillar scores (each 0..100 + availability + confidence) ----
    final HealthPillar cashFlow = _cashFlow(
        income, expenseToIncome, discretionaryRatio, f.plannedExpenseMinor,
        f.expenseMinor);
    final HealthPillar savings =
        _savings(income, savingsRate, posMonthRatio, active, f.goalsCount, f.goalsProgress);
    final HealthPillar resilience =
        _resilience(coverage, posMonthRatio, active);
    final HealthPillar debt = _debt(income, dti, dsr, f.owedByMeMinor);
    final HealthPillar incomeStab = _incomeStability(cv, active);
    final HealthPillar planning = _planning(f.goalsCount, f.goalsProgress);

    final List<HealthPillar> pillars = <HealthPillar>[
      cashFlow, savings, resilience, debt, incomeStab, planning,
    ];

    // ---- Weighted score over AVAILABLE pillars (renormalized) ----
    double wsum = 0;
    double acc = 0;
    for (final HealthPillar p in pillars) {
      if (!p.available) continue;
      wsum += p.weight;
      acc += p.weight * p.score;
    }
    final double base = wsum <= 0 ? 0 : acc / wsum;

    // ---- Critical-risk analysis + caps ----
    final List<HealthRisk> risks = <HealthRisk>[];
    double cap = 100;
    final int recentNet = _recentNet(f, 3);
    final int yearNet = f.incomeMinor - f.expenseMinor;
    if (yearNet < 0) {
      risks.add(const HealthRisk(RiskKind.negativeCashFlow));
      cap = math.min(cap, recentNet < 0 ? 45 : 60);
    }
    if (income > 0 && expenseToIncome >= 1.0) {
      risks.add(HealthRisk(RiskKind.spendingExceedsIncome, ratio: expenseToIncome));
      cap = math.min(cap, 50);
    }
    if (income > 0 && dsr >= 0.5) {
      risks.add(HealthRisk(RiskKind.highDebtService, ratio: dsr));
      cap = math.min(cap, 50);
    }
    if (income > 0 && dti >= 3.0) {
      risks.add(HealthRisk(RiskKind.highDebtToIncome, ratio: dti));
      cap = math.min(cap, 55);
    }
    // Only when KNOWN (not when data is missing).
    if (coverage != null && avgEssentialMonthly > 0 && coverage < 1.0) {
      risks.add(HealthRisk(RiskKind.noEmergencyBuffer, months: coverage));
      cap = math.min(cap, 70);
    }
    if (active >= 3 && cv >= 0.6) {
      risks.add(HealthRisk(RiskKind.incomeInstability, ratio: cv));
      cap = math.min(cap, 65);
    }

    final double score = base.clamp(0, cap).toDouble();

    // ---- Data Confidence (separate from the score) ----
    final double confidence = _confidence(pillars, active);

    // ---- Financial Resilience (separate lens; includes debt headroom) ----
    final double resScore = _resilienceScore(
        coverage, dsr, savingsRate, cv, active);

    // ---- Strengths / weaknesses / trend ----
    final List<HealthPillar> avail =
        pillars.where((HealthPillar p) => p.available).toList()
          ..sort((HealthPillar a, HealthPillar b) => b.score.compareTo(a.score));
    final List<HealthPillarKey> strengths = avail
        .where((HealthPillar p) => p.score >= 70)
        .take(3)
        .map((HealthPillar p) => p.key)
        .toList();
    final List<HealthPillarKey> weaknesses = avail.reversed
        .where((HealthPillar p) => p.score < 60)
        .take(3)
        .map((HealthPillar p) => p.key)
        .toList();

    return HealthReport(
      score: score,
      status: statusOf(score),
      confidence: confidence,
      resilience: resScore,
      pillars: pillars,
      risks: risks,
      strengths: strengths,
      weaknesses: weaknesses,
      trend: _trend(f),
      emergencyMonths: coverage,
      hasData: true,
    );
  }

  // ---------------- pillar builders ----------------

  static HealthPillar _cashFlow(double income, double expToInc,
      double discRatio, int planned, int expense) {
    if (income <= 0) {
      return const HealthPillar(
          key: HealthPillarKey.cashFlow,
          score: 0,
          weight: 0.25,
          available: false,
          confidence: 0);
    }
    // Sub-metrics (spending discipline only — surplus lives in Savings, so the
    // net/income ratio is never double-counted here).
    final double sExp = _anchors(expToInc, const <List<double>>[
      <double>[0.5, 100], <double>[0.7, 78], <double>[0.9, 48],
      <double>[1.0, 28], <double>[1.2, 0],
    ]);
    final double sDisc = _anchors(discRatio, const <List<double>>[
      <double>[0.10, 100], <double>[0.25, 80], <double>[0.40, 50],
      <double>[0.60, 20], <double>[0.80, 0],
    ]);
    double wSum = 0.55 + 0.20;
    double acc = 0.55 * sExp + 0.20 * sDisc;
    double conf = 0.85;
    if (planned > 0 && expense >= 0) {
      final double ratio = planned == 0 ? 1 : expense / planned;
      final double sBudget = _anchors(ratio, const <List<double>>[
        <double>[0.6, 90], <double>[1.0, 100], <double>[1.1, 80],
        <double>[1.25, 55], <double>[1.5, 25], <double>[2.0, 0],
      ]);
      wSum += 0.25;
      acc += 0.25 * sBudget;
      conf = 1.0;
    }
    return HealthPillar(
      key: HealthPillarKey.cashFlow,
      score: (acc / wSum).clamp(0, 100).toDouble(),
      weight: 0.25,
      available: true,
      confidence: conf,
    );
  }

  static HealthPillar _savings(double income, double savingsRate,
      double posMonthRatio, int active, int goalsCount, double goalsProgress) {
    if (income <= 0) {
      return const HealthPillar(
          key: HealthPillarKey.savings,
          score: 0,
          weight: 0.20,
          available: false,
          confidence: 0);
    }
    final double sRate = _anchors(savingsRate, const <List<double>>[
      <double>[-0.1, 0], <double>[0.0, 15], <double>[0.05, 35],
      <double>[0.10, 60], <double>[0.20, 88], <double>[0.30, 100],
    ]);
    double wSum = 0.60;
    double acc = 0.60 * sRate;
    double conf = 0.8;
    if (active >= 3) {
      wSum += 0.25;
      acc += 0.25 * (posMonthRatio * 100);
      conf = 0.95;
    }
    if (goalsCount > 0) {
      wSum += 0.15;
      acc += 0.15 * (goalsProgress.clamp(0, 1) * 100);
    }
    return HealthPillar(
      key: HealthPillarKey.savings,
      score: (acc / wSum).clamp(0, 100).toDouble(),
      weight: 0.20,
      available: true,
      confidence: conf,
    );
  }

  static HealthPillar _resilience(
      double? coverage, double posMonthRatio, int active) {
    // Liquidity buffer. Primary = emergency coverage; when unknown we fall back
    // to saving-consistency only and drop the confidence (never assume good).
    if (coverage == null) {
      if (active < 3) {
        return const HealthPillar(
            key: HealthPillarKey.resilience,
            score: 0,
            weight: 0.20,
            available: false,
            confidence: 0);
      }
      return HealthPillar(
        key: HealthPillarKey.resilience,
        score: (posMonthRatio * 100).clamp(0, 100).toDouble(),
        weight: 0.20,
        available: true,
        confidence: 0.45, // no emergency-fund data → low confidence
      );
    }
    final double sCover = _anchors(coverage, const <List<double>>[
      <double>[0, 0], <double>[1, 25], <double>[3, 70], <double>[6, 100],
    ]);
    final double acc = 0.70 * sCover + 0.30 * (posMonthRatio * 100);
    return HealthPillar(
      key: HealthPillarKey.resilience,
      score: acc.clamp(0, 100).toDouble(),
      weight: 0.20,
      available: true,
      confidence: 1.0,
    );
  }

  static HealthPillar _debt(
      double income, double dti, double dsr, int owedByMe) {
    if (income <= 0) {
      return const HealthPillar(
          key: HealthPillarKey.debt,
          score: 0,
          weight: 0.20,
          available: false,
          confidence: 0);
    }
    if (owedByMe == 0 && dsr <= 0) {
      // No debt at all = fully manageable (not a gap).
      return const HealthPillar(
          key: HealthPillarKey.debt,
          score: 100,
          weight: 0.20,
          available: true,
          confidence: 1.0);
    }
    final double sDti = _anchors(dti, const <List<double>>[
      <double>[0, 100], <double>[0.5, 82], <double>[1, 62],
      <double>[2, 38], <double>[3, 18], <double>[4, 0],
    ]);
    final double sDsr = _anchors(dsr, const <List<double>>[
      <double>[0, 100], <double>[0.1, 90], <double>[0.2, 72],
      <double>[0.36, 46], <double>[0.5, 20], <double>[0.6, 0],
    ]);
    return HealthPillar(
      key: HealthPillarKey.debt,
      score: (0.5 * sDti + 0.5 * sDsr).clamp(0, 100).toDouble(),
      weight: 0.20,
      available: true,
      confidence: 0.9,
    );
  }

  static HealthPillar _incomeStability(double cv, int active) {
    if (active < 3) {
      return const HealthPillar(
          key: HealthPillarKey.incomeStability,
          score: 0,
          weight: 0.10,
          available: false,
          confidence: 0);
    }
    final double s = _anchors(cv, const <List<double>>[
      <double>[0, 100], <double>[0.1, 85], <double>[0.25, 62],
      <double>[0.4, 40], <double>[0.6, 20], <double>[0.8, 0],
    ]);
    return HealthPillar(
      key: HealthPillarKey.incomeStability,
      score: s,
      weight: 0.10,
      available: true,
      confidence: active >= 6 ? 1.0 : 0.7,
    );
  }

  static HealthPillar _planning(int goalsCount, double goalsProgress) {
    if (goalsCount <= 0) {
      return const HealthPillar(
          key: HealthPillarKey.planning,
          score: 0,
          weight: 0.05,
          available: false,
          confidence: 0);
    }
    return HealthPillar(
      key: HealthPillarKey.planning,
      score: (goalsProgress.clamp(0, 1) * 100).toDouble(),
      weight: 0.05,
      available: true,
      confidence: 0.9,
    );
  }

  // ---------------- resilience (standalone lens) ----------------

  static double _resilienceScore(
      double? coverage, double dsr, double savingsRate, double cv, int active) {
    double wSum = 0;
    double acc = 0;
    if (coverage != null) {
      final double s = _anchors(coverage, const <List<double>>[
        <double>[0, 0], <double>[1, 25], <double>[3, 70], <double>[6, 100],
      ]);
      wSum += 0.50;
      acc += 0.50 * s;
    }
    // Debt-service headroom (ability to absorb without new debt).
    final double head = _anchors(dsr, const <List<double>>[
      <double>[0, 100], <double>[0.2, 75], <double>[0.36, 50],
      <double>[0.5, 20], <double>[0.6, 0],
    ]);
    wSum += 0.25;
    acc += 0.25 * head;
    // Ongoing surplus to rebuild buffers.
    final double sr = _anchors(savingsRate, const <List<double>>[
      <double>[-0.1, 0], <double>[0, 20], <double>[0.1, 60], <double>[0.2, 100],
    ]);
    wSum += 0.15;
    acc += 0.15 * sr;
    if (active >= 3) {
      final double stab = _anchors(cv, const <List<double>>[
        <double>[0, 100], <double>[0.25, 60], <double>[0.5, 30], <double>[0.8, 0],
      ]);
      wSum += 0.10;
      acc += 0.10 * stab;
    }
    return wSum <= 0 ? 0 : (acc / wSum).clamp(0, 100).toDouble();
  }

  // ---------------- data confidence ----------------

  static double _confidence(List<HealthPillar> pillars, int active) {
    double wAll = 0;
    double wConf = 0;
    for (final HealthPillar p in pillars) {
      wAll += p.weight;
      wConf += p.weight * (p.available ? p.confidence : 0);
    }
    final double coverageFactor = wAll <= 0 ? 0 : wConf / wAll;
    final double monthsFactor = _anchors(active.toDouble(), const <List<double>>[
      <double>[1, 0.5], <double>[3, 0.75], <double>[6, 0.9], <double>[12, 1.0],
    ]);
    return (coverageFactor * monthsFactor * 100).clamp(0, 100).toDouble();
  }

  // ---------------- temporal trend ----------------

  static HealthTrend _trend(HealthFacts f) {
    final List<int> net = <int>[
      for (int i = 0; i < 12; i++) f.monthlyIncome[i] - f.monthlyExpense[i],
    ];
    final List<int> activeNet = <int>[
      for (int i = 0; i < 12; i++)
        if (f.monthlyIncome[i] != 0 || f.monthlyExpense[i] != 0) net[i],
    ];
    if (activeNet.length < 4) return HealthTrend.unknown;
    final int half = (activeNet.length / 2).floor();
    final List<int> prior = activeNet.sublist(0, half);
    final List<int> recent = activeNet.sublist(activeNet.length - half);
    final double pa = prior.fold<int>(0, (int s, int v) => s + v) / prior.length;
    final double ra =
        recent.fold<int>(0, (int s, int v) => s + v) / recent.length;
    final double delta = ra - pa;
    final double scale = math.max(pa.abs(), 1);
    if (delta > 0.08 * scale) return HealthTrend.improving;
    if (delta < -0.08 * scale) return HealthTrend.declining;
    return HealthTrend.stable;
  }

  // ---------------- helpers ----------------

  static int _activeMonths(HealthFacts f) {
    int n = 0;
    for (int i = 0; i < 12; i++) {
      if (f.monthlyIncome[i] != 0 || f.monthlyExpense[i] != 0) n++;
    }
    return n;
  }

  static int _recentNet(HealthFacts f, int months) {
    final List<int> activeIdx = <int>[
      for (int i = 0; i < 12; i++)
        if (f.monthlyIncome[i] != 0 || f.monthlyExpense[i] != 0) i,
    ];
    if (activeIdx.isEmpty) return 0;
    int sum = 0;
    for (final int i in activeIdx.reversed.take(months)) {
      sum += f.monthlyIncome[i] - f.monthlyExpense[i];
    }
    return sum;
  }

  static double _positiveNetMonthRatio(HealthFacts f, int active) {
    if (active <= 0) return 0;
    int pos = 0;
    for (int i = 0; i < 12; i++) {
      if (f.monthlyIncome[i] == 0 && f.monthlyExpense[i] == 0) continue;
      if (f.monthlyIncome[i] - f.monthlyExpense[i] > 0) pos++;
    }
    return pos / active;
  }

  static double _incomeCv(List<int> monthly, int active) {
    final List<int> vals = <int>[
      for (final int v in monthly) if (v != 0) v,
    ];
    if (vals.length < 3) return 0; // unknown → neutral; availability gates use
    final double mean =
        vals.fold<int>(0, (int s, int v) => s + v) / vals.length;
    if (mean == 0) return 0;
    final double variance = vals.fold<double>(
          0,
          (double s, int v) => s + math.pow(v - mean, 2).toDouble(),
        ) /
        vals.length;
    return math.sqrt(variance) / mean;
  }

  static double? _coverageMonths(int? emergency, double avgMonthlyEssential) {
    if (emergency == null) return null; // unknown
    if (avgMonthlyEssential <= 0) return emergency > 0 ? 6.0 : 0.0;
    return emergency / avgMonthlyEssential;
  }

  /// Piecewise-linear map of [x] through sorted (x,y) anchors, clamped to ends.
  static double _anchors(double x, List<List<double>> pts) {
    if (x <= pts.first[0]) return pts.first[1];
    if (x >= pts.last[0]) return pts.last[1];
    for (int i = 0; i < pts.length - 1; i++) {
      final List<double> a = pts[i];
      final List<double> b = pts[i + 1];
      if (x >= a[0] && x <= b[0]) {
        final double t = (x - a[0]) / (b[0] - a[0]);
        return a[1] + t * (b[1] - a[1]);
      }
    }
    return pts.last[1];
  }
}
