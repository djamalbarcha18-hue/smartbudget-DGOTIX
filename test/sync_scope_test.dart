import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/sync/domain/sync_merge.dart';
import 'package:smartbudget/features/sync/domain/sync_scope.dart';

/// A device running one round the way SyncController does, with a scope.
class Device {
  Device(this.scope);
  SyncScope scope;
  Records records = <String, Map<String, Map<String, dynamic>>>{};
  Entries ledger = <String, Map<String, SyncEntry>>{};

  void put(String c, String id, Map<String, dynamic> data) =>
      records.putIfAbsent(c, () => <String, Map<String, dynamic>>{})[id] =
          <String, dynamic>{'id': id, ...data};

  void remove(String c, String id) => records[c]?.remove(id);

  Map<String, dynamic>? sync(Map<String, dynamic>? cloud, int now) {
    final Entries pruned = scope.pruneLedger(ledger, records);
    final Entries local =
        SyncMerge.detect(pruned, scope.local(records, pruned), now);
    final Entries cloudAll = SyncMerge.fromCloud(cloud);
    final Entries merged =
        SyncMerge.merge(local, scope.cloudIn(cloudAll, local, records), now: now);
    records = scope.compose(records, merged);
    ledger = SyncMerge.rebase(merged, records);
    return SyncMerge.toCloud(
        scope.withHeld(ledger, scope.cloudHeld(cloudAll, local, records)));
  }

  Map<String, Map<String, dynamic>> col(String c) =>
      records[c] ?? <String, Map<String, dynamic>>{};
}

final DateTime now = DateTime(2026, 11, 15);
String ago(int months, [int day = 10]) =>
    DateTime(now.year, now.month - months, day).toIso8601String();

void main() {
  final SyncScope free = SyncScope.free(now);
  const SyncScope full = SyncScope.full();
  const int t = 1000;

  test('free scope covers the current month and the two before it', () {
    expect(free.includes('transactions', <String, dynamic>{'date': ago(0)}),
        isTrue);
    expect(free.includes('transactions', <String, dynamic>{'date': ago(2, 1)}),
        isTrue);
    expect(free.includes('transactions', <String, dynamic>{'date': ago(3)}),
        isFalse);
    expect(
        free.includes('budgets', <String, dynamic>{'year': 2026, 'month': 9}),
        isTrue);
    expect(
        free.includes('budgets', <String, dynamic>{'year': 2026, 'month': 8}),
        isFalse);
  });

  test('free scope leaves PRO collections out, full scope leaves none out', () {
    expect(free.allowsCollection('goals'), isFalse);
    expect(free.allowsCollection('debts'), isFalse);
    expect(free.allowsCollection('wallets'), isFalse);
    expect(free.allowsCollection('transactions'), isTrue);
    expect(free.allowsCollection('customCategories.expense'), isTrue);
    expect(full.allowsCollection('goals'), isTrue);
  });

  test('free: recent transactions reach the other device, old ones do not', () {
    final Device a = Device(free), b = Device(free);
    a.put('transactions', 'new', <String, dynamic>{'date': ago(1)});
    a.put('transactions', 'old', <String, dynamic>{'date': ago(8)});
    a.put('goals', 'g', <String, dynamic>{'target': 5});
    Map<String, dynamic>? cloud = a.sync(null, t);
    cloud = b.sync(cloud, t + 1);
    expect(b.col('transactions').keys, <String>['new']);
    expect(b.col('goals'), isEmpty);
    // Nothing was removed from the device that entered them.
    expect(a.col('transactions').keys.toSet(), <String>{'new', 'old'});
    expect(a.col('goals').keys, <String>['g']);
  });

  test('a record that ages out of the window is not deleted anywhere', () {
    final Device a = Device(free), b = Device(free);
    a.put('transactions', 'x', <String, dynamic>{'date': ago(2, 28)});
    Map<String, dynamic>? cloud = a.sync(null, t);
    cloud = b.sync(cloud, t + 1);
    expect(b.col('transactions').keys, <String>['x']);
    // Months pass: x is now outside the window on both devices.
    final SyncScope later = SyncScope.free(DateTime(2027, 3, 15));
    a.scope = later;
    b.scope = later;
    cloud = a.sync(cloud, t + 2);
    cloud = b.sync(cloud, t + 3);
    cloud = a.sync(cloud, t + 4);
    expect(a.col('transactions').keys, <String>['x']);
    expect(b.col('transactions').keys, <String>['x']);
    expect(SyncMerge.fromCloud(cloud)['transactions']!['x']!.deleted, isFalse);
  });

  test('a deletion inside the window still reaches the other device', () {
    final Device a = Device(free), b = Device(free);
    a.put('transactions', 'x', <String, dynamic>{'date': ago(0)});
    Map<String, dynamic>? cloud = a.sync(null, t);
    cloud = b.sync(cloud, t + 1);
    b.remove('transactions', 'x');
    cloud = b.sync(cloud, t + 2);
    a.sync(cloud, t + 3);
    expect(a.col('transactions'), isEmpty);
  });

  test('free sync never wipes what PRO put in the cloud', () {
    final Device pro = Device(full), free1 = Device(free);
    pro.put('goals', 'g', <String, dynamic>{'target': 9});
    pro.put('transactions', 'old', <String, dynamic>{'date': ago(8)});
    pro.put('transactions', 'new', <String, dynamic>{'date': ago(0)});
    Map<String, dynamic>? cloud = pro.sync(null, t);
    // A downgraded device syncs, adds a recent transaction, uploads.
    cloud = free1.sync(cloud, t + 1);
    free1.put('transactions', 'mine', <String, dynamic>{'date': ago(0)});
    cloud = free1.sync(cloud, t + 2);
    final Entries c = SyncMerge.fromCloud(cloud);
    expect(c['goals']!['g']!.deleted, isFalse);
    expect(c['transactions']!['old']!.deleted, isFalse);
    expect(c['transactions']!['mine']!.deleted, isFalse);
  });

  test('upgrading to PRO then syncs the older history and PRO data', () {
    final Device a = Device(free), b = Device(free);
    a.put('transactions', 'old', <String, dynamic>{'date': ago(8)});
    a.put('goals', 'g', <String, dynamic>{'target': 3});
    Map<String, dynamic>? cloud = a.sync(null, t);
    a.scope = full;
    b.scope = full;
    cloud = a.sync(cloud, t + 1);
    b.sync(cloud, t + 2);
    expect(b.col('transactions').keys, <String>['old']);
    expect(b.col('goals').keys, <String>['g']);
  });

  // ---- Regressions: edits to older records were undone by the next sync ----

  test('moving a transaction to an older month is not undone', () {
    final Device a = Device(free), b = Device(free);
    a.put('transactions', 'x', <String, dynamic>{'date': ago(0), 'amount': 70});
    Map<String, dynamic>? cloud = a.sync(null, t);
    cloud = b.sync(cloud, t + 1);
    // The user moves it six months back (outside the free window).
    a.put('transactions', 'x', <String, dynamic>{'date': ago(6), 'amount': 70});
    cloud = a.sync(cloud, t + 2);
    cloud = a.sync(cloud, t + 3); // the next automatic round
    expect(a.col('transactions')['x']!['date'], ago(6));
    // The move reaches the other device too.
    cloud = b.sync(cloud, t + 4);
    expect(b.col('transactions')['x']!['date'], ago(6));
  });

  test('editing a transaction that aged out of the window is not undone', () {
    final Device a = Device(free), b = Device(free);
    a.put('transactions', 'x', <String, dynamic>{'date': ago(2, 28), 'amount': 70});
    Map<String, dynamic>? cloud = a.sync(null, t);
    cloud = b.sync(cloud, t + 1);
    final SyncScope later = SyncScope.free(DateTime(2027, 3, 15));
    a.scope = later;
    b.scope = later;
    cloud = a.sync(cloud, t + 2);
    a.put('transactions', 'x', <String, dynamic>{'date': ago(2, 28), 'amount': 999});
    cloud = a.sync(cloud, t + 3);
    cloud = a.sync(cloud, t + 4);
    expect(a.col('transactions')['x']!['amount'], 999);
    b.sync(cloud, t + 5);
    expect(b.col('transactions')['x']!['amount'], 999);
  });

  test('deleting a transaction that aged out reaches the other device', () {
    final Device a = Device(free), b = Device(free);
    a.put('transactions', 'x', <String, dynamic>{'date': ago(2, 28)});
    Map<String, dynamic>? cloud = a.sync(null, t);
    cloud = b.sync(cloud, t + 1);
    final SyncScope later = SyncScope.free(DateTime(2027, 3, 15));
    a.scope = later;
    b.scope = later;
    cloud = a.sync(cloud, t + 2);
    cloud = b.sync(cloud, t + 3);
    a.remove('transactions', 'x');
    cloud = a.sync(cloud, t + 4);
    cloud = a.sync(cloud, t + 5);
    expect(a.col('transactions'), isEmpty);
    b.sync(cloud, t + 6);
    expect(b.col('transactions'), isEmpty);
  });

  test('editing an old budget is not undone', () {
    final Device a = Device(free);
    a.put('budgets', 'b', <String, dynamic>{
      'year': 2026, 'month': 11, 'category': 'food', 'amount': 100});
    Map<String, dynamic>? cloud = a.sync(null, t);
    a.scope = SyncScope.free(DateTime(2027, 5, 1));
    cloud = a.sync(cloud, t + 1);
    a.put('budgets', 'b', <String, dynamic>{
      'year': 2026, 'month': 11, 'category': 'food', 'amount': 250});
    cloud = a.sync(cloud, t + 2);
    a.sync(cloud, t + 3);
    expect(a.col('budgets')['b']!['amount'], 250);
  });

  test("an old cloud record never overwrites the device's own copy", () {
    final Device pro = Device(full), freeDev = Device(free);
    pro.put('transactions', 'x', <String, dynamic>{'date': ago(8), 'amount': 1});
    final Map<String, dynamic>? cloud = pro.sync(null, t);
    // The free device holds its own, different copy of x (e.g. a restore).
    freeDev.put('transactions', 'x', <String, dynamic>{'date': ago(8), 'amount': 2});
    final Map<String, dynamic>? after = freeDev.sync(cloud, t + 1);
    expect(freeDev.col('transactions')['x']!['amount'], 2);
    // And the cloud keeps the PRO copy untouched.
    expect(SyncMerge.fromCloud(after)['transactions']!['x']!.data!['amount'], 1);
  });

  test('a new free device still receives the older history in the cloud', () {
    final Device pro = Device(full), fresh = Device(free);
    pro.put('transactions', 'old', <String, dynamic>{'date': ago(8)});
    pro.put('transactions', 'new', <String, dynamic>{'date': ago(0)});
    final Map<String, dynamic>? cloud = pro.sync(null, t);
    fresh.sync(cloud, t + 1);
    expect(fresh.col('transactions').keys.toSet(), <String>{'old', 'new'});
  });

  test('a downloaded old record can then be edited and deleted for good', () {
    final Device pro = Device(full), fresh = Device(free);
    pro.put('transactions', 'old', <String, dynamic>{'date': ago(8), 'amount': 5});
    Map<String, dynamic>? cloud = pro.sync(null, t);
    cloud = fresh.sync(cloud, t + 1);
    fresh.put('transactions', 'old', <String, dynamic>{'date': ago(8), 'amount': 6});
    cloud = fresh.sync(cloud, t + 2);
    cloud = fresh.sync(cloud, t + 3);
    expect(fresh.col('transactions')['old']!['amount'], 6);
    fresh.remove('transactions', 'old');
    cloud = fresh.sync(cloud, t + 4);
    cloud = fresh.sync(cloud, t + 5);
    expect(fresh.col('transactions'), isEmpty);
    pro.sync(cloud, t + 6);
    expect(pro.col('transactions'), isEmpty);
  });

  test('full scope behaves exactly as before', () {
    final Records r = <String, Map<String, Map<String, dynamic>>>{
      'goals': <String, Map<String, dynamic>>{
        'g': <String, dynamic>{'id': 'g'},
      },
    };
    expect(identical(full.filter(r), r), isTrue);
  });
}
