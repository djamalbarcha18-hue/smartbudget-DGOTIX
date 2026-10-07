import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/sync/domain/sync_merge.dart';

/// A device: what it stores and its ledger. sync() runs one full round with
/// the cloud copy, as SyncController does (detect, merge, apply, upload).
class Device {
  Records records = <String, Map<String, Map<String, dynamic>>>{};
  Entries ledger = <String, Map<String, SyncEntry>>{};

  Map<String, Map<String, dynamic>> col(String c) =>
      records.putIfAbsent(c, () => <String, Map<String, dynamic>>{});

  void put(String c, String id, Map<String, dynamic> data) =>
      col(c)[id] = <String, dynamic>{'id': id, ...data};

  void remove(String c, String id) => col(c).remove(id);

  /// Notices local changes (also offline).
  void detect(int now) => ledger = SyncMerge.detect(ledger, records, now);

  Map<String, dynamic>? sync(Map<String, dynamic>? cloud, int now) {
    detect(now);
    final Entries merged =
        SyncMerge.merge(ledger, SyncMerge.fromCloud(cloud), now: now);
    records = SyncMerge.recordsOf(merged);
    ledger = SyncMerge.rebase(merged, records);
    return SyncMerge.toCloud(ledger);
  }
}

const int day = 86400000;

void main() {
  test('a record added on one device reaches the other', () {
    final Device a = Device(), b = Device();
    a.put('transactions', 't1', <String, dynamic>{'amount': 100});
    Map<String, dynamic>? cloud = a.sync(null, 1000);
    cloud = b.sync(cloud, 2000);
    expect(b.col('transactions')['t1']?['amount'], 100);
  });

  test('the newest edit wins, on both devices', () {
    final Device a = Device(), b = Device();
    a.put('goals', 'g1', <String, dynamic>{'target': 10});
    Map<String, dynamic>? cloud = a.sync(null, 1000);
    cloud = b.sync(cloud, 1100);
    // Both edit offline: A at 2000, B later at 3000.
    a.put('goals', 'g1', <String, dynamic>{'target': 20});
    a.detect(2000);
    b.put('goals', 'g1', <String, dynamic>{'target': 30});
    b.detect(3000);
    cloud = a.sync(cloud, 4000);
    cloud = b.sync(cloud, 5000);
    cloud = a.sync(cloud, 6000);
    expect(a.col('goals')['g1']?['target'], 30);
    expect(b.col('goals')['g1']?['target'], 30);
  });

  test('a deletion reaches the other device and nothing comes back', () {
    final Device a = Device(), b = Device();
    a.put('debts', 'd1', <String, dynamic>{'party': 'Ali'});
    Map<String, dynamic>? cloud = a.sync(null, 1000);
    cloud = b.sync(cloud, 1100);
    a.remove('debts', 'd1');
    cloud = a.sync(cloud, 2000);
    cloud = b.sync(cloud, 3000);
    expect(b.col('debts').containsKey('d1'), isFalse);
    cloud = a.sync(cloud, 4000);
    expect(a.col('debts').containsKey('d1'), isFalse);
  });

  test('an edit made after a deletion elsewhere wins (and the reverse)', () {
    final Device a = Device(), b = Device();
    a.put('wallets', 'w1', <String, dynamic>{'name': 'Cash'});
    Map<String, dynamic>? cloud = a.sync(null, 1000);
    cloud = b.sync(cloud, 1100);
    a.remove('wallets', 'w1');
    a.detect(2000);
    b.put('wallets', 'w1', <String, dynamic>{'name': 'Cash 2'});
    b.detect(3000);
    cloud = a.sync(cloud, 4000);
    cloud = b.sync(cloud, 5000);
    cloud = a.sync(cloud, 6000);
    expect(a.col('wallets')['w1']?['name'], 'Cash 2');

    a.remove('wallets', 'w1');
    a.detect(7000);
    cloud = a.sync(cloud, 7000);
    b.sync(cloud, 8000);
    expect(b.col('wallets').containsKey('w1'), isFalse);
  });

  test('different records changed on two devices are all kept', () {
    final Device a = Device(), b = Device();
    a.put('transactions', 'ta', <String, dynamic>{'amount': 1});
    b.put('transactions', 'tb', <String, dynamic>{'amount': 2});
    Map<String, dynamic>? cloud = a.sync(null, 1000);
    cloud = b.sync(cloud, 2000);
    cloud = a.sync(cloud, 3000);
    expect(a.col('transactions').keys, containsAll(<String>['ta', 'tb']));
    expect(b.col('transactions').keys, containsAll(<String>['ta', 'tb']));
  });

  test('a backup made by an older version is merged, newer local changes win',
      () {
    final Map<String, dynamic> legacy = <String, dynamic>{
      'schemaVersion': 1,
      'baseCurrency': 'DZD',
      'transactions': <Map<String, dynamic>>[
        <String, dynamic>{'id': 't1', 'amount': 5},
        <String, dynamic>{'id': 't2', 'amount': 7},
      ],
      'customCategories': <String, dynamic>{
        'income': <String>['Freelance'],
        'expense': <String>[],
      },
    };
    final Device a = Device();
    a.put('transactions', 't1', <String, dynamic>{'amount': 50});
    a.sync(legacy, 1000);
    expect(a.col('transactions')['t1']?['amount'], 50);
    expect(a.col('transactions')['t2']?['amount'], 7);
    expect(a.col('customCategories.income').keys, contains('Freelance'));
    expect(a.col('settings')['baseCurrency']?['value'], 'DZD');
  });

  test('budgets for the same category and month made on two devices become one',
      () {
    final Device a = Device(), b = Device();
    a.put('budgets', 'ba', <String, dynamic>{'year': 2026, 'month': 10, 'category': 'Food', 'planned': 100});
    b.put('budgets', 'bb', <String, dynamic>{'year': 2026, 'month': 10, 'category': 'Food', 'planned': 150});
    Map<String, dynamic>? cloud = a.sync(null, 1000);
    cloud = b.sync(cloud, 2000);
    cloud = a.sync(cloud, 3000);
    expect(a.col('budgets').length, 1);
    expect(a.col('budgets').values.single['planned'], 150);
    expect(b.col('budgets').length, 1);
  });

  test('a tie settles the same way on both devices', () {
    final Device a = Device(), b = Device();
    a.put('goals', 'g', <String, dynamic>{'v': 'A'});
    b.put('goals', 'g', <String, dynamic>{'v': 'B'});
    a.detect(1000);
    b.detect(1000);
    Map<String, dynamic>? cloud = a.sync(null, 1000);
    cloud = b.sync(cloud, 1000);
    a.sync(cloud, 1000);
    expect(a.col('goals')['g']?['v'], b.col('goals')['g']?['v']);
  });

  test('old deletions are forgotten', () {
    final Device a = Device();
    a.put('goals', 'g', <String, dynamic>{'v': 1});
    a.sync(null, 0);
    a.remove('goals', 'g');
    final Map<String, dynamic>? cloud = a.sync(null, 1000);
    expect(SyncMerge.fromCloud(cloud)['goals']!.containsKey('g'), isTrue);
    final Map<String, dynamic>? later = a.sync(cloud, 1000 + 121 * day);
    expect(SyncMerge.fromCloud(later)['goals']!.containsKey('g'), isFalse);
  });

  test('a record stored in its normal form is not taken for an edit', () {
    final Device a = Device();
    a.put('transactions', 't', <String, dynamic>{'amount': 1, 'note': 'x'});
    a.sync(null, 1000);
    // Same content, keys in another order.
    a.col('transactions')['t'] = <String, dynamic>{'note': 'x', 'amount': 1, 'id': 't'};
    a.detect(5000);
    expect(a.ledger['transactions']!['t']!.t, 1000);
  });

  test('records survive the trip through the backup format', () {
    final Records r = SyncMerge.recordsFromBackup(<String, dynamic>{
      'baseCurrency': 'EUR',
      'transactions': <Map<String, dynamic>>[
        <String, dynamic>{'id': 't1', 'amount': 1},
      ],
      'wallets': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'w1', 'name': 'Bank'},
      ],
      'customCategories': <String, dynamic>{
        'income': <String>['Rent'],
        'expense': <String>['Pets'],
      },
    });
    final Map<String, dynamic> back = SyncMerge.backupFromRecords(r);
    expect(back['baseCurrency'], 'EUR');
    expect(back['transactions'], <Map<String, dynamic>>[
      <String, dynamic>{'id': 't1', 'amount': 1},
    ]);
    expect(back['customCategories'], <String, dynamic>{
      'income': <String>['Rent'],
      'expense': <String>['Pets'],
    });
    final Entries ledger = SyncMerge.ledgerFromJson(
        SyncMerge.ledgerToJson(SyncMerge.detect(
            <String, Map<String, SyncEntry>>{}, r, 42)));
    expect(ledger['wallets']!['w1']!.t, 42);
    expect(ledger['wallets']!['w1']!.deleted, isFalse);
  });
}
