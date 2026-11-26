import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';
import 'package:smartbudget/features/sync/domain/sync_merge.dart';
import 'package:smartbudget/features/sync/domain/sync_scope.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

Subscription netflix({String id = 'sub-nf'}) => Subscription(
      id: id,
      ruleId: id,
      kind: SubscriptionKind.digital,
      provider: 'Netflix',
      catalogId: 'netflix',
      planName: 'Standard',
      trialEndsAt: DateTime(2026, 12, 15),
      billedVia: BilledVia.googlePlay,
      manageUrl: 'https://example.com/manage',
      notes: 'family',
      reminderDays: const <int>[3, 1],
      reminderMinutes: 9 * 60 + 30,
      keptUntil: DateTime(2026, 12, 15),
      status: SubscriptionStatus.trial,
      cancelRequestedAt: DateTime(2026, 12, 1, 10, 5),
      paidUntil: DateTime(2027, 1, 15),
      payments: const <String, String>{'2026-12-15': 'rec-sub-nf-20261215'},
      createdAt: DateTime(2026, 11, 26, 6),
      updatedAt: DateTime(2026, 11, 26, 7),
    );

RecurringRule rule(String id) => RecurringRule(
      id: id,
      type: TransactionType.expense,
      category: 'الاشتراكات',
      amount: const Money(1500, 'USD'),
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 12, 15),
      lastPosted: DateTime(2026, 12, 14),
      createdAt: DateTime(2026, 11, 26),
    );

/// A device running one round the way SyncController does (as in
/// sync_scope_test.dart).
class Device {
  Device(this.scope);
  SyncScope scope;
  Records records = <String, Map<String, Map<String, dynamic>>>{};
  Entries ledger = <String, Map<String, SyncEntry>>{};

  void put(String c, String id, Map<String, dynamic> data) =>
      records.putIfAbsent(c, () => <String, Map<String, dynamic>>{})[id] =
          <String, dynamic>{'id': id, ...data};

  Map<String, dynamic>? sync(Map<String, dynamic>? cloud, int now) {
    final Entries pruned = scope.pruneLedger(ledger, records);
    final Entries local =
        SyncMerge.detect(pruned, scope.local(records, pruned), now);
    final Entries cloudAll = SyncMerge.fromCloud(cloud);
    final Entries merged = SyncMerge.merge(
        local, scope.cloudIn(cloudAll, local, records),
        now: now);
    records = scope.compose(records, merged);
    ledger = SyncMerge.rebase(merged, records);
    return SyncMerge.toCloud(
        scope.withHeld(ledger, scope.cloudHeld(cloudAll, local, records)));
  }

  Map<String, Map<String, dynamic>> col(String c) =>
      records[c] ?? <String, Map<String, dynamic>>{};
}

void main() {
  group('Subscription JSON', () {
    test('every field survives a round-trip', () {
      final Subscription s = netflix();
      final Subscription back =
          Subscription.fromJson(jsonDecode(jsonEncode(s.toJson())));
      expect(back.toJson(), s.toJson());
      expect(back.trialEndsAt, DateTime(2026, 12, 15));
      expect(back.reminderMinutes, 570);
      expect(back.status, SubscriptionStatus.trial);
      expect(back.isTrial, isTrue);
      expect(back.payments['2026-12-15'], 'rec-sub-nf-20261215');
    });

    test('dates are calendar days, not instants', () {
      final Map<String, dynamic> j = netflix().toJson();
      expect(j['trialEndsAt'], '2026-12-15');
      expect(j['paidUntil'], '2027-01-15');
      // A stored instant still reads as its calendar day.
      j['paidUntil'] = '2027-01-15T23:30:00.000';
      expect(Subscription.fromJson(j).paidUntil, DateTime(2027, 1, 15));
    });

    test('a minimal record loads with safe defaults', () {
      final Subscription s = Subscription.fromJson(<String, dynamic>{
        'id': 'sub-x',
        'provider': 'Spotify',
        'createdAt': '2026-11-26T06:00:00.000',
      });
      expect(s.ruleId, 'sub-x');
      expect(s.kind, SubscriptionKind.digital);
      expect(s.autoRenew, isTrue);
      expect(s.remindersOn, isTrue);
      expect(s.status, SubscriptionStatus.active);
      expect(s.reminderDays, isEmpty);
      expect(s.payments, isEmpty);
      expect(s.updatedAt, s.createdAt);
    });

    test('values from a newer version fall back to the safe side', () {
      final Map<String, dynamic> j = netflix().toJson()
        ..['status'] = 'somethingNew'
        ..['billedVia'] = 'newStore'
        ..['reminderDays'] = <Object?>[1, 'x', 99, 3, 1, -2];
      final Subscription s = Subscription.fromJson(j);
      // Unknown status keeps the reminders coming.
      expect(s.status, SubscriptionStatus.active);
      expect(s.billedVia, BilledVia.other);
      expect(s.reminderDays, <int>[3, 1]);
    });

    test('ended and confirmed cancellations are over, a request is not', () {
      Subscription at(SubscriptionStatus st) => netflix().copyWith(status: st);
      expect(at(SubscriptionStatus.ended).isOver, isTrue);
      expect(at(SubscriptionStatus.cancelConfirmed).isOver, isTrue);
      expect(at(SubscriptionStatus.cancelRequested).isOver, isFalse);
      expect(at(SubscriptionStatus.activeUntilEnd).isOver, isFalse);
    });

    test('copyWith can clear the trial and the kept-until date', () {
      final Subscription s =
          netflix().copyWith(clearTrial: true, clearKept: true);
      expect(s.trialEndsAt, isNull);
      expect(s.keptUntil, isNull);
      expect(s.provider, 'Netflix');
    });
  });

  group('Reminder days per cycle', () {
    test('choices and defaults follow the cycle', () {
      expect(SubscriptionReminders.choicesFor(RecurrenceFrequency.weekly),
          <int>[1, 0]);
      expect(SubscriptionReminders.defaultsFor(RecurrenceFrequency.weekly),
          <int>[1]);
      expect(SubscriptionReminders.choicesFor(RecurrenceFrequency.monthly),
          <int>[3, 1, 0]);
      expect(SubscriptionReminders.defaultsFor(RecurrenceFrequency.monthly),
          <int>[3, 1]);
      expect(SubscriptionReminders.choicesFor(RecurrenceFrequency.yearly),
          <int>[7, 3, 1, 0]);
      expect(SubscriptionReminders.defaultsFor(RecurrenceFrequency.yearly),
          <int>[7, 1]);
      expect(SubscriptionReminders.trialDays, <int>[2, 1]);
    });

    test('a choice the cycle does not offer is dropped', () {
      final Subscription s =
          netflix().copyWith(reminderDays: const <int>[7, 3]);
      expect(SubscriptionReminders.daysFor(s, RecurrenceFrequency.monthly),
          <int>[3]);
      // Nothing valid left: the defaults.
      expect(SubscriptionReminders.daysFor(s, RecurrenceFrequency.weekly),
          <int>[1]);
      expect(SubscriptionReminders.daysFor(s, RecurrenceFrequency.yearly),
          <int>[7, 3]);
    });
  });

  group('Backup', () {
    BackupData sample() => BackupData(
          exportedAt: DateTime(2026, 11, 26),
          baseCurrency: 'DZD',
          transactions: const <Transaction>[],
          budgets: const [],
          customIncome: const <String>[],
          customExpense: const <String>[],
          recurring: <RecurringRule>[rule('sub-nf')],
          subscriptions: <Subscription>[netflix()],
        );

    test('subscriptions survive a backup file round-trip', () {
      final BackupData back =
          BackupCodec.decodeJson(BackupCodec.encodeJson(sample()));
      expect(back.subscriptions.single.toJson(), netflix().toJson());
      expect(back.recurring.single.id, 'sub-nf');
    });

    test('a file holding only subscriptions is recognised', () {
      expect(BackupCodec.decodeJson('{"subscriptions":[]}').subscriptions,
          isEmpty);
    });

    test('older backups without subscriptions still load', () {
      final BackupData d = BackupCodec.decodeJson('{"transactions":[]}');
      expect(d.subscriptions, isEmpty);
    });

    test('cloud records carry subscriptions both ways', () {
      final Records r = SyncMerge.recordsFromBackup(sample().toJson());
      expect(r['subscriptions']!.keys, <String>['sub-nf']);
      final BackupData back =
          BackupData.fromJson(SyncMerge.backupFromRecords(r));
      expect(back.subscriptions.single.provider, 'Netflix');
    });
  });

  group('Sync scope', () {
    final SyncScope free = SyncScope.free(DateTime(2026, 11, 26));

    test('free syncs subscriptions and only their rules', () {
      expect(free.allowsCollection('subscriptions'), isTrue);
      expect(free.allowsCollection('recurring'), isTrue);
      expect(free.includes('recurring', <String, dynamic>{'id': 'sub-nf'}),
          isTrue);
      expect(free.includes('recurring', <String, dynamic>{'id': 'rule-rent'}),
          isFalse);
      expect(free.includes('recurring', <String, dynamic>{}), isFalse);
      expect(SyncScope.subscriptionRulePrefix, Subscription.idPrefix);
    });

    test('free: a subscription and its rule reach the other device, '
        'other rules stay where they were entered', () {
      final Device a = Device(free), b = Device(free);
      a.put('subscriptions', 'sub-nf', netflix().toJson());
      a.put('recurring', 'sub-nf', rule('sub-nf').toJson());
      a.put('recurring', 'rule-rent', rule('rule-rent').toJson());
      Map<String, dynamic>? cloud = a.sync(null, 1000);
      cloud = b.sync(cloud, 1001);
      expect(b.col('subscriptions').keys, <String>['sub-nf']);
      expect(b.col('recurring').keys, <String>['sub-nf']);
      // Nothing was removed from the device that entered them.
      expect(a.col('recurring').keys.toSet(), <String>{'sub-nf', 'rule-rent'});
    });

    test('free: deleting a subscription reaches the other device', () {
      final Device a = Device(free), b = Device(free);
      a.put('subscriptions', 'sub-nf', netflix().toJson());
      Map<String, dynamic>? cloud = a.sync(null, 1000);
      cloud = b.sync(cloud, 1001);
      expect(b.col('subscriptions').keys, <String>['sub-nf']);
      a.records['subscriptions']!.remove('sub-nf');
      cloud = a.sync(cloud, 2000);
      b.sync(cloud, 2001);
      expect(b.col('subscriptions'), isEmpty);
    });

    test('a device that holds no subscriptions sends the cloud ones back', () {
      // As an older app version would: it has nothing in that collection.
      final Device a = Device(const SyncScope.full());
      a.put('subscriptions', 'sub-nf', netflix().toJson());
      final Map<String, dynamic>? cloud = a.sync(null, 1000);
      final Device other = Device(const SyncScope.full());
      other.put('transactions', 't1', <String, dynamic>{'date': '2026-11-20'});
      final Map<String, dynamic>? back = other.sync(cloud, 1001);
      final Entries after = SyncMerge.fromCloud(back);
      expect(after['subscriptions']!['sub-nf']!.deleted, isFalse);
    });
  });
}
