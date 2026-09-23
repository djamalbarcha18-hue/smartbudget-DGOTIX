import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Smart alerts — forward-looking and pattern-based notifications, reserved
/// for yearly subscribers. Pure (no Flutter, no IO) and derived only from the
/// user's own transactions: every alert states a real figure, and nothing is
/// shown when there isn't enough history to say something meaningful.
///
/// Only transactions in [currency] (the base currency) are considered, the same
/// rule the rest of the app's summaries follow.
abstract final class SmartAlertEngine {
  /// Forecasts start once this many days of the month have passed.
  static const int forecastFromDay = 5;

  /// …and need at least this many day-to-day expenses in the category.
  static const int forecastMinExpenses = 3;

  /// A forecast is raised when the projection passes the budget by 10%.
  static const double forecastMargin = 1.10;

  /// A single expense is unusual at this multiple of the category's median.
  static const double unusualMultiple = 3;

  /// …judged against at least this many earlier expenses in the category.
  static const int unusualMinHistory = 4;
  static const int unusualLookbackDays = 90;
  static const int unusualRecentDays = 7;

  /// A category spikes when this month passes its recent average by 50%.
  static const double spikeMultiple = 1.5;
  static const int spikeMinMonths = 2;

  /// Most alerts of one kind shown at once.
  static const int maxPerKind = 3;

  /// The monthly summary is shown during the first days of the new month.
  static const int monthlyDigestDays = 7;

  static List<AppAlert> build({
    required List<Transaction> transactions,
    required Map<String, int> plannedThisMonth,
    required String currency,
    required DateTime now,
  }) {
    final List<Transaction> txns = transactions
        .where((Transaction t) => t.amount.currencyCode == currency)
        .toList();
    if (txns.isEmpty) return const <AppAlert>[];
    final AppAlert? weekly = weeklyDigest(txns, currency, now);
    final AppAlert? monthly = monthlyDigest(txns, currency, now);
    return <AppAlert>[
      ...budgetForecasts(txns, plannedThisMonth, currency, now),
      ...unusualExpenses(txns, currency, now),
      ...categorySpikes(txns, currency, now),
      if (weekly != null) weekly,
      if (monthly != null) monthly,
    ];
  }

  // ---- helpers ----

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  static bool _inMonth(Transaction t, int y, int m) =>
      t.date.year == y && t.date.month == m;

  static int _median(List<int> v) {
    final List<int> s = List<int>.of(v)..sort();
    final int mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : ((s[mid - 1] + s[mid]) / 2).round();
  }

  /// Expense total per category, and the category with the most.
  static Map<String, int> _byCategory(Iterable<Transaction> txns) {
    final Map<String, int> out = <String, int>{};
    for (final Transaction t in txns) {
      if (!t.isExpense) continue;
      out[t.category] = (out[t.category] ?? 0) + t.amount.minorUnits;
    }
    return out;
  }

  static String _top(Map<String, int> byCat) {
    String top = '';
    int max = 0;
    byCat.forEach((String c, int v) {
      if (v > max) {
        max = v;
        top = c;
      }
    });
    return top;
  }

  // ---- 1. Budget forecast ----

  /// Categories that, at this month's pace, will end over their budget.
  /// Recurring items count once (they don't repeat within the month); only the
  /// day-to-day spending is projected to month end.
  static List<AppAlert> budgetForecasts(
    List<Transaction> txns,
    Map<String, int> planned,
    String currency,
    DateTime now,
  ) {
    final int day = now.day;
    final int dim = _daysInMonth(now.year, now.month);
    if (day < forecastFromDay || day >= dim) return const <AppAlert>[];

    final List<({String cat, int over})> hits = <({String cat, int over})>[];
    planned.forEach((String cat, int budget) {
      if (budget <= 0) return;
      int fixed = 0;
      int variable = 0;
      int count = 0;
      for (final Transaction t in txns) {
        if (!t.isExpense || t.category != cat) continue;
        if (!_inMonth(t, now.year, now.month) || t.date.day > day) continue;
        if (RecurrenceEngine.isRecurring(t)) {
          fixed += t.amount.minorUnits;
        } else {
          variable += t.amount.minorUnits;
          count++;
        }
      }
      final int actual = fixed + variable;
      // Already near/over budget: the regular budget alerts cover it.
      if (actual >= budget * 0.9) return;
      if (count < forecastMinExpenses) return;
      final int projected = fixed + (variable * dim / day).round();
      if (projected > budget * forecastMargin) {
        hits.add((cat: cat, over: projected - budget));
      }
    });
    hits.sort((a, b) => b.over.compareTo(a.over));
    return <AppAlert>[
      for (final ({String cat, int over}) h in hits.take(maxPerKind))
        AppAlert(
          kind: AlertKind.budgetForecast,
          severity: AlertSeverity.medium,
          subject: h.cat,
          amount: Money(h.over, currency),
          route: '/budget',
          focusKey: h.cat,
        ),
    ];
  }

  // ---- 2. Unusual spending ----

  /// Recent single expenses far above the category's usual amount.
  static List<AppAlert> unusualExpenses(
    List<Transaction> txns,
    String currency,
    DateTime now,
  ) {
    final DateTime today = _day(now);
    final DateTime recentFrom =
        DateTime(today.year, today.month, today.day - (unusualRecentDays - 1));
    final List<({Transaction t, int median, double x})> hits =
        <({Transaction t, int median, double x})>[];
    for (final Transaction t in txns) {
      if (!t.isExpense || RecurrenceEngine.isRecurring(t)) continue;
      final DateTime d = _day(t.date);
      if (d.isBefore(recentFrom) || d.isAfter(today)) continue;
      final DateTime from =
          DateTime(d.year, d.month, d.day - unusualLookbackDays);
      final List<int> history = <int>[
        for (final Transaction h in txns)
          if (h.id != t.id &&
              h.isExpense &&
              h.category == t.category &&
              !RecurrenceEngine.isRecurring(h) &&
              !_day(h.date).isBefore(from) &&
              _day(h.date).isBefore(d))
            h.amount.minorUnits,
      ];
      if (history.length < unusualMinHistory) continue;
      final int median = _median(history);
      if (median <= 0) continue;
      final double x = t.amount.minorUnits / median;
      if (x >= unusualMultiple) hits.add((t: t, median: median, x: x));
    }
    hits.sort((a, b) => b.x.compareTo(a.x));
    return <AppAlert>[
      for (final ({Transaction t, int median, double x}) h
          in hits.take(maxPerKind))
        AppAlert(
          kind: AlertKind.unusualExpense,
          severity: AlertSeverity.medium,
          subject: h.t.category,
          amount: h.t.amount,
          compareAmount: Money(h.median, currency),
          route: '/transactions',
          focusKey: h.t.id,
          date: _day(h.t.date),
        ),
    ];
  }

  /// Categories whose spending this month already passes their recent
  /// monthly average by [spikeMultiple]. The average uses the previous three
  /// months that have any activity (at least [spikeMinMonths] of them).
  static List<AppAlert> categorySpikes(
    List<Transaction> txns,
    String currency,
    DateTime now,
  ) {
    final List<(int, int)> months = <(int, int)>[];
    for (int back = 1; back <= 3; back++) {
      final DateTime m = DateTime(now.year, now.month - back, 1);
      if (txns.any((Transaction t) => _inMonth(t, m.year, m.month))) {
        months.add((m.year, m.month));
      }
    }
    if (months.length < spikeMinMonths) return const <AppAlert>[];

    final Map<String, int> history = <String, int>{};
    for (final (int y, int m) in months) {
      _byCategory(txns.where((Transaction t) => _inMonth(t, y, m)))
          .forEach((String c, int v) => history[c] = (history[c] ?? 0) + v);
    }
    final Map<String, int> current = _byCategory(txns.where(
        (Transaction t) => _inMonth(t, now.year, now.month) &&
            !_day(t.date).isAfter(_day(now))));

    final List<({String cat, int now, int avg})> hits =
        <({String cat, int now, int avg})>[];
    current.forEach((String cat, int spent) {
      final int avg = ((history[cat] ?? 0) / months.length).round();
      if (avg <= 0) return;
      if (spent > avg * spikeMultiple) {
        hits.add((cat: cat, now: spent, avg: avg));
      }
    });
    hits.sort((a, b) => (b.now - b.avg).compareTo(a.now - a.avg));
    return <AppAlert>[
      for (final ({String cat, int now, int avg}) h in hits.take(maxPerKind))
        AppAlert(
          kind: AlertKind.categorySpike,
          severity: AlertSeverity.medium,
          subject: h.cat,
          amount: Money(h.now, currency),
          compareAmount: Money(h.avg, currency),
          route: '/reports',
          focusKey: h.cat,
        ),
    ];
  }

  // ---- 3. Summaries ----

  /// The last completed Monday–Sunday week: spending, the week before it (when
  /// it has activity) and where most of it went. Null when the week is empty.
  static AppAlert? weeklyDigest(
    List<Transaction> txns,
    String currency,
    DateTime now,
  ) {
    final DateTime today = _day(now);
    final DateTime thisWeek =
        DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final DateTime start =
        DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7);
    final DateTime prevStart = DateTime(start.year, start.month, start.day - 7);

    bool within(Transaction t, DateTime from, DateTime to) {
      final DateTime d = _day(t.date);
      return !d.isBefore(from) && d.isBefore(to);
    }

    final List<Transaction> week =
        txns.where((Transaction t) => within(t, start, thisWeek)).toList();
    if (week.isEmpty) return null;
    final List<Transaction> prev =
        txns.where((Transaction t) => within(t, prevStart, start)).toList();

    final Map<String, int> byCat = _byCategory(week);
    final int spent = byCat.values.fold(0, (int a, int b) => a + b);
    final int prevSpent =
        _byCategory(prev).values.fold(0, (int a, int b) => a + b);
    return AppAlert(
      kind: AlertKind.weeklyDigest,
      severity: AlertSeverity.info,
      subject: _top(byCat),
      amount: Money(spent, currency),
      compareAmount: prevSpent > 0 ? Money(prevSpent, currency) : null,
      route: '/reports',
      date: start,
    );
  }

  /// The month that just ended — income, spending, savings rate and the top
  /// category — shown during the first [monthlyDigestDays] days of the new one.
  static AppAlert? monthlyDigest(
    List<Transaction> txns,
    String currency,
    DateTime now,
  ) {
    if (now.day > monthlyDigestDays) return null;
    final DateTime pm = DateTime(now.year, now.month - 1, 1);
    final List<Transaction> month = txns
        .where((Transaction t) => _inMonth(t, pm.year, pm.month))
        .toList();
    if (month.isEmpty) return null;
    int income = 0;
    for (final Transaction t in month) {
      if (t.isIncome) income += t.amount.minorUnits;
    }
    final Map<String, int> byCat = _byCategory(month);
    final int spent = byCat.values.fold(0, (int a, int b) => a + b);
    return AppAlert(
      kind: AlertKind.monthlyDigest,
      severity: AlertSeverity.info,
      subject: _top(byCat),
      amount: Money(spent, currency),
      compareAmount: Money(income, currency),
      ratio: income > 0 ? (income - spent) / income : null,
      route: '/reports',
      date: pm,
    );
  }
}
