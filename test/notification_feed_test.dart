import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/notifications/domain/notification_feed.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

AppAlert overBudget(String cat) => AppAlert(
      kind: AlertKind.budgetOver,
      severity: AlertSeverity.high,
      subject: cat,
      amount: const Money(1000, 'USD'),
      route: '/budget',
      focusKey: cat,
    );

RecurringRule rent({
  required DateTime start,
  DateTime? lastPosted,
  bool active = true,
}) =>
    RecurringRule(
      id: 'rule-rent',
      type: TransactionType.expense,
      category: 'السكن',
      amount: const Money(70000, 'USD'),
      description: 'Rent',
      frequency: RecurrenceFrequency.monthly,
      startDate: start,
      lastPosted: lastPosted ?? start,
      active: active,
      createdAt: DateTime(2026, 1, 1),
    );

List<FeedItem> feed(List<AppAlert> finance, DateTime now,
        {List<AppAlert> upcoming = const <AppAlert>[], bool backup = false}) =>
    NotificationFeed.build(
      finance: finance,
      upcoming: upcoming,
      backupDue: backup,
      currency: 'USD',
      now: now,
    );

void main() {
  group('renewal', () {
    test('a seen alert stays read within the month', () {
      final DateTime sep = DateTime(2026, 9, 10);
      final List<FeedItem> items = feed(<AppAlert>[overBudget('food')], sep);
      final Set<String> seen = items.map((FeedItem f) => f.id).toSet();
      expect(
          NotificationFeed.unread(
              feed(<AppAlert>[overBudget('food')], DateTime(2026, 9, 28)),
              seen),
          isEmpty);
    });

    test('the same situation notifies again in a new month', () {
      final Set<String> seen = feed(<AppAlert>[overBudget('food')],
              DateTime(2026, 9, 10))
          .map((FeedItem f) => f.id)
          .toSet();
      expect(
          NotificationFeed.unread(
              feed(<AppAlert>[overBudget('food')], DateTime(2026, 10, 2)),
              seen),
          hasLength(1));
    });

    test('a different category is new even when another was seen', () {
      final DateTime now = DateTime(2026, 9, 10);
      final Set<String> seen = feed(<AppAlert>[overBudget('food')], now)
          .map((FeedItem f) => f.id)
          .toSet();
      final Set<String> unread = NotificationFeed.unread(
          feed(<AppAlert>[overBudget('food'), overBudget('transport')], now),
          seen);
      expect(unread.single, contains('transport'));
    });

    test('duplicate ids collapse into one notification', () {
      final List<FeedItem> items = feed(
          <AppAlert>[overBudget('food'), overBudget('food')],
          DateTime(2026, 9, 10));
      expect(items, hasLength(1));
    });
  });

  group('upcoming recurring', () {
    test('announced within three days, not before', () {
      final RecurringRule r = rent(
          start: DateTime(2026, 1, 25), lastPosted: DateTime(2026, 8, 25));
      expect(NotificationFeed.upcomingRecurring(<RecurringRule>[r],
              DateTime(2026, 9, 21)),
          isEmpty);
      final List<AppAlert> soon = NotificationFeed.upcomingRecurring(
          <RecurringRule>[r], DateTime(2026, 9, 22, 9));
      expect(soon.single.date, DateTime(2026, 9, 25));
      expect(soon.single.subject, 'Rent');
      expect(soon.single.route, '/recurring');
    });

    test('paused rules are not announced', () {
      final RecurringRule r = rent(
          start: DateTime(2026, 1, 25),
          lastPosted: DateTime(2026, 8, 25),
          active: false);
      expect(NotificationFeed.upcomingRecurring(<RecurringRule>[r],
              DateTime(2026, 9, 24)),
          isEmpty);
    });

    test('each occurrence is its own notification', () {
      final RecurringRule r = rent(
          start: DateTime(2026, 1, 25), lastPosted: DateTime(2026, 8, 25));
      final List<FeedItem> sep = feed(const <AppAlert>[], DateTime(2026, 9, 23),
          upcoming: NotificationFeed.upcomingRecurring(
              <RecurringRule>[r], DateTime(2026, 9, 23)));
      final RecurringRule posted = r.copyWith(lastPosted: DateTime(2026, 9, 25));
      final List<FeedItem> oct = feed(
          const <AppAlert>[], DateTime(2026, 10, 23),
          upcoming: NotificationFeed.upcomingRecurring(
              <RecurringRule>[posted], DateTime(2026, 10, 23)));
      expect(sep.single.id, isNot(oct.single.id));
      expect(
          NotificationFeed.unread(
              oct, sep.map((FeedItem f) => f.id).toSet()),
          hasLength(1));
    });
  });

  test('backup reminder joins the feed; most urgent first', () {
    final List<FeedItem> items = feed(
        <AppAlert>[overBudget('food')], DateTime(2026, 9, 10),
        backup: true);
    expect(items.map((FeedItem f) => f.alert.kind), <AlertKind>[
      AlertKind.budgetOver,
      AlertKind.backupDue,
    ]);
  });
}
