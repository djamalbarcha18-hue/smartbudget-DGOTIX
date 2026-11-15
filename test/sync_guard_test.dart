import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/sync/domain/sync_guard.dart';
import 'package:smartbudget/features/sync/domain/sync_merge.dart';

/// Deletions a sync round can't trust must never reach the other devices.
void main() {
  const int now = 5000;

  Records txns(Iterable<String> ids) => <String, Map<String, Map<String, dynamic>>>{
        'transactions': <String, Map<String, dynamic>>{
          for (final String id in ids) id: <String, dynamic>{'id': id},
        },
      };

  Entries ledgerOf(Iterable<String> ids) =>
      SyncMerge.detect(<String, Map<String, SyncEntry>>{}, txns(ids), 1000);

  test('a normal deletion goes through', () {
    final Entries ledger = ledgerOf(<String>['a', 'b', 'c']);
    final Entries local =
        SyncMerge.detect(ledger, txns(<String>['a', 'b']), now);
    final Entries out =
        SyncGuard.withoutSuspectDeletions(ledger, local, readLoss: false);
    expect(out['transactions']!['c']!.deleted, isTrue);
  });

  test('after a read problem, missing records are not sent as deletions', () {
    final Entries ledger = ledgerOf(<String>['a', 'b', 'c']);
    final Entries local =
        SyncMerge.detect(ledger, txns(<String>['a']), now);
    final Entries out =
        SyncGuard.withoutSuspectDeletions(ledger, local, readLoss: true);
    expect(out['transactions']!.containsKey('b'), isFalse);
    expect(out['transactions']!.containsKey('c'), isFalse);
    expect(out['transactions']!['a']!.deleted, isFalse);
  });

  test('a large list that comes back empty is not deleted everywhere', () {
    final List<String> ids = <String>[for (int i = 0; i < 12; i++) 't$i'];
    final Entries ledger = ledgerOf(ids);
    final Entries local = SyncMerge.detect(ledger, txns(<String>[]), now);
    final Entries out =
        SyncGuard.withoutSuspectDeletions(ledger, local, readLoss: false);
    expect(out['transactions'], isEmpty);
  });

  test('the cloud copy then brings the records back', () {
    final List<String> ids = <String>[for (int i = 0; i < 12; i++) 't$i'];
    final Entries ledger = ledgerOf(ids);
    final Entries cloud = ledger.map((String c, Map<String, SyncEntry> m) =>
        MapEntry<String, Map<String, SyncEntry>>(c, <String, SyncEntry>{
          for (final MapEntry<String, SyncEntry> e in m.entries)
            e.key: SyncEntry(t: e.value.t, data: <String, dynamic>{'id': e.key}),
        }));
    final Entries local = SyncGuard.withoutSuspectDeletions(
        ledger, SyncMerge.detect(ledger, txns(<String>[]), now),
        readLoss: false);
    final Entries merged = SyncMerge.merge(local, cloud, now: now);
    expect(SyncMerge.recordsOf(merged)['transactions']!.keys.toSet(),
        ids.toSet());
  });

  test('deleting a few records of a large list still goes through', () {
    final List<String> ids = <String>[for (int i = 0; i < 12; i++) 't$i'];
    final Entries ledger = ledgerOf(ids);
    final Entries local =
        SyncMerge.detect(ledger, txns(ids.skip(3)), now);
    final Entries out =
        SyncGuard.withoutSuspectDeletions(ledger, local, readLoss: false);
    expect(out['transactions']!['t0']!.deleted, isTrue);
  });

  test('an unreadable ledger lets newer cloud edits win', () {
    final Entries local = SyncGuard.untimed(SyncMerge.detect(
        <String, Map<String, SyncEntry>>{},
        <String, Map<String, Map<String, dynamic>>>{
          'transactions': <String, Map<String, dynamic>>{
            'a': <String, dynamic>{'id': 'a', 'amount': 1},
            'mine': <String, dynamic>{'id': 'mine'},
          },
        },
        now));
    final Entries cloud = <String, Map<String, SyncEntry>>{
      'transactions': <String, SyncEntry>{
        'a': const SyncEntry(t: 3000, data: <String, dynamic>{'id': 'a', 'amount': 2}),
        'gone': const SyncEntry(t: 3000),
      },
    };
    final Records r =
        SyncMerge.recordsOf(SyncMerge.merge(local, cloud, now: now));
    expect(r['transactions']!['a']!['amount'], 2);
    // What only this device has is kept and uploaded.
    expect(r['transactions']!.containsKey('mine'), isTrue);
  });
}
