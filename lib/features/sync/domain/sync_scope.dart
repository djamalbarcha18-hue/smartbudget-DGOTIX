/// What a sync round covers.
///
/// PRO syncs everything. FREE syncs the basics — transactions, budgets and
/// custom categories — for the last [freeMonths] months, so a person can use
/// the app on a phone and a computer and see the same recent data on both.
///
/// The rule that matters: leaving the scope never removes anything. A record
/// that is older than the window, or in a collection FREE doesn't sync, is
/// neither uploaded nor deleted: it stays on the device it was entered on, and
/// whatever the cloud already holds of it is carried along untouched. PRO
/// then syncs it all.
library;

import 'package:smartbudget/features/sync/domain/sync_merge.dart';

class SyncScope {
  const SyncScope._(this._cutoff, this._collections);

  /// Everything (PRO, the trial, the beta).
  const SyncScope.full() : this._(null, null);

  /// The free scope as of [now]: the current month and the [freeMonths] - 1
  /// before it.
  factory SyncScope.free(DateTime now) => SyncScope._(
        DateTime(now.year, now.month - (freeMonths - 1)),
        freeCollections,
      );

  /// How many months back the free scope reaches (this month included).
  static const int freeMonths = 3;

  /// The collections FREE syncs.
  static const Set<String> freeCollections = <String>{
    'transactions',
    'budgets',
    'customCategories.income',
    'customCategories.expense',
    'settings',
  };

  final DateTime? _cutoff;
  final Set<String>? _collections;

  bool get isFull => _collections == null;

  bool allowsCollection(String c) => _collections?.contains(c) ?? true;

  /// Whether [record] of [collection] is inside the scope.
  bool includes(String collection, Map<String, dynamic> record) {
    if (!allowsCollection(collection)) return false;
    final DateTime? cut = _cutoff;
    if (cut == null) return true;
    switch (collection) {
      case 'transactions':
        final DateTime? d = DateTime.tryParse('${record['date']}');
        // A date that can't be read is kept in scope: better synced than lost.
        return d == null || !d.isBefore(cut);
      case 'budgets':
        final Object? y = record['year'], m = record['month'];
        if (y is! num || m is! num) return true;
        return !DateTime(y.toInt(), m.toInt()).isBefore(cut);
      default:
        return true;
    }
  }

  /// The part of [all] inside the scope.
  Records filter(Records all) {
    if (isFull) return all;
    return <String, Map<String, Map<String, dynamic>>>{
      for (final MapEntry<String, Map<String, Map<String, dynamic>>> c
          in all.entries)
        if (allowsCollection(c.key))
          c.key: <String, Map<String, dynamic>>{
            for (final MapEntry<String, Map<String, dynamic>> r
                in c.value.entries)
              if (includes(c.key, r.value)) r.key: r.value,
          },
    };
  }

  /// [ledger] without the entries of records that are still on the device but
  /// left the scope (aged out). Without this they would be read as deleted and
  /// the deletion would reach the other devices.
  Entries pruneLedger(Entries ledger, Records all) {
    if (isFull) return ledger;
    final Records inScope = filter(all);
    return <String, Map<String, SyncEntry>>{
      for (final MapEntry<String, Map<String, SyncEntry>> c in ledger.entries)
        if (allowsCollection(c.key))
          c.key: <String, SyncEntry>{
            for (final MapEntry<String, SyncEntry> e in c.value.entries)
              if (!_leftScope(c.key, e.key, all, inScope)) e.key: e.value,
          },
    };
  }

  static bool _leftScope(
          String c, String id, Records all, Records inScope) =>
      all[c]?.containsKey(id) == true && inScope[c]?.containsKey(id) != true;

  /// The cloud entries the scope covers.
  Entries cloudIn(Entries cloud) {
    if (isFull) return cloud;
    return <String, Map<String, SyncEntry>>{
      for (final MapEntry<String, Map<String, SyncEntry>> c in cloud.entries)
        if (allowsCollection(c.key)) c.key: c.value,
    };
  }

  /// The cloud entries the scope does not cover: sent back as they were.
  Entries cloudHeld(Entries cloud) {
    if (isFull) return const <String, Map<String, SyncEntry>>{};
    return <String, Map<String, SyncEntry>>{
      for (final MapEntry<String, Map<String, SyncEntry>> c in cloud.entries)
        if (!allowsCollection(c.key)) c.key: c.value,
    };
  }

  /// [merged] plus the [held] cloud entries, for the document to upload.
  Entries withHeld(Entries merged, Entries held) {
    if (held.isEmpty) return merged;
    return <String, Map<String, SyncEntry>>{...merged, ...held};
  }

  /// What the device should hold after a round: everything it had, minus what
  /// the merge says was deleted, with the merged records written over it.
  /// Records outside the scope are therefore never touched.
  Records compose(Records all, Entries merged) {
    if (isFull) return SyncMerge.recordsOf(merged);
    final Records target = SyncMerge.recordsOf(merged);
    final Records out = <String, Map<String, Map<String, dynamic>>>{};
    for (final String c in <String>{...all.keys, ...target.keys}) {
      if (!allowsCollection(c)) {
        if (all[c] != null) out[c] = all[c]!;
        continue;
      }
      final Map<String, SyncEntry> m =
          merged[c] ?? const <String, SyncEntry>{};
      out[c] = <String, Map<String, dynamic>>{
        for (final MapEntry<String, Map<String, dynamic>> r
            in (all[c] ?? const <String, Map<String, dynamic>>{}).entries)
          if (m[r.key]?.deleted != true) r.key: r.value,
        ...?target[c],
      };
    }
    return out;
  }
}
