import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/card_suggestions.dart';
import 'package:smartbudget/features/subscriptions/domain/service_catalog.dart';
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
      cardName: 'Edahabia',
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

  group('Card name', () {
    test('a name, or a name with the last four digits, is kept', () {
      expect(CardName.clean('  Edahabia '), 'Edahabia');
      expect(CardName.clean('Visa BNA ...4417'), 'Visa BNA ...4417');
      expect(CardName.clean('بطاقة الذهبية'), 'بطاقة الذهبية');
      expect(netflix().cardName, 'Edahabia');
    });

    test('anything that looks like a card number is refused', () {
      expect(CardName.isSafe('4111 1111 1111 1111'), isFalse);
      expect(CardName.clean('4111-1111-1111-1111'), isNull);
      expect(CardName.clean('Visa 41111'), isNull);
      expect(CardName.clean('6280.5800.1234'), isNull);
    });

    test('empty becomes null and long names are shortened', () {
      expect(CardName.clean('   '), isNull);
      expect(CardName.clean(null), isNull);
      expect(CardName.clean('x' * 60)!.length, CardName.maxLength);
    });

    test('a stored card number is dropped on load', () {
      final Map<String, dynamic> j = netflix().toJson()
        ..['cardName'] = '4111111111111111';
      expect(Subscription.fromJson(j).cardName, isNull);
    });

    test('copyWith can clear the card name', () {
      expect(netflix().copyWith(clearCard: true).cardName, isNull);
      expect(netflix().copyWith(cardName: 'CIB').cardName, 'CIB');
    });
  });

  group('Service catalog', () {
    test('ids are unique and every name is filled in', () {
      final Set<String> ids = <String>{};
      for (final CatalogService s in ServiceCatalog.all) {
        expect(ids.add(s.id), isTrue, reason: s.id);
        expect(s.name.trim(), isNotEmpty);
      }
      expect(ServiceCatalog.all.length, 25);
    });

    test('Algeria sees its carriers first, others do not see them', () {
      final List<CatalogService> dz = ServiceCatalog.forCountry('dz');
      expect(dz.take(4).map((CatalogService s) => s.name), <String>[
        'Djezzy',
        'Mobilis',
        'Ooredoo',
        'Algérie Télécom (Idoom)',
      ]);
      expect(dz.length, ServiceCatalog.all.length);
      final List<CatalogService> fr = ServiceCatalog.forCountry('FR');
      expect(fr.any((CatalogService s) => s.country == 'DZ'), isFalse);
      expect(fr.first.name, 'Netflix');
    });

    test('phone and home internet plans are of the mobile kind', () {
      expect(ServiceCatalog.byId('dz_djezzy')!.kind, SubscriptionKind.mobile);
      expect(ServiceCatalog.byId('dz_idoom')!.kind, SubscriptionKind.mobile);
      expect(ServiceCatalog.byId('netflix')!.kind, SubscriptionKind.digital);
      expect(ServiceCatalog.byId('nope'), isNull);
      expect(ServiceCatalog.byId(null), isNull);
    });

    test('search narrows by name', () {
      expect(ServiceCatalog.search('DZ', 'pre').map((CatalogService s) => s.id),
          <String>['youtube_premium', 'telegram_premium']);
    });

    test('no prices and no unchecked links are shipped', () {
      // Cancel links are added only once checked by hand (plan, 5.3).
      expect(ServiceCatalog.all.where((CatalogService s) => s.manageUrl != null),
          isEmpty);
    });
  });

  group('Plan', () {
    test('five subscriptions free, unlimited on PRO', () {
      expect(FeatureCatalog.minTierFor(Feature.subscriptions), Plan.free);
      expect(FeatureCatalog.quotaFor(Feature.subscriptions, Plan.free)!.limit,
          5);
      expect(
          FeatureCatalog.quotaFor(Feature.subscriptions, Plan.pro)!.isUnlimited,
          isTrue);
    });

    test('a subscription rule is told apart from an ordinary one', () {
      expect(rule('sub-nf').isSubscription, isTrue);
      expect(rule('rule-rent').isSubscription, isFalse);
      expect(Subscription.idPrefix, RecurringRule.subscriptionPrefix);
    });
  });

  group('Card suggestions', () {
    test('Algeria: its own cards first, then the global ones, no repeats', () {
      final List<String> dz = CardSuggestions.forCountry('dz');
      expect(dz.take(5), <String>[
        'الذهبية (Edahabia)',
        'CIB',
        'RedotPay',
        'PayPal',
        'Payoneer',
      ]);
      expect(dz, contains('Visa'));
      expect(dz.where((String n) => n == 'PayPal').length, 1);
      expect(dz.where((String n) => n == 'RedotPay').length, 1);
    });

    test('other countries get theirs, unknown ones the global list', () {
      expect(CardSuggestions.forCountry('SA').first, 'mada');
      expect(CardSuggestions.forCountry('EG').first, 'Meeza');
      expect(CardSuggestions.forCountry('XX'), CardSuggestions.global);
      expect(CardSuggestions.forCountry(null), CardSuggestions.global);
    });

    test('every suggestion is a safe card name', () {
      for (final List<String> l in <List<String>>[
        CardSuggestions.global,
        ...CardSuggestions.byCountry.values,
      ]) {
        for (final String n in l) {
          expect(CardName.clean(n), n, reason: n);
        }
      }
    });

    test('autocomplete narrows by what was typed', () {
      expect(CardSuggestions.matching('DZ', 'pay'),
          <String>['RedotPay', 'PayPal', 'Payoneer', 'Google Pay', 'Apple Pay']);
      expect(CardSuggestions.matching('DZ', ''),
          CardSuggestions.forCountry('DZ'));
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
