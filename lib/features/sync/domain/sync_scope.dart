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
///
/// The other rule: the cloud never overwrites a record this device holds
/// unless that record is in the round. A record synced once stays in the
/// round (see [SyncScope.local]), so its edits and deletions keep reaching
/// the other devices after it leaves the window.
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

  /// What this device syncs: the records inside the window, plus every record
  /// the [ledger] already knows (it was synced before). A known record keeps
  /// syncing after it ages out of the window or is moved out of it, so an
  /// edit to it is uploaded and a deletion of it reaches the other devices.
  /// Before, such a record dropped out of the round and the next download
  /// wrote the older cloud copy back over the edit.
  Records local(Records all, Entries ledger) {
    if (isFull) return all;
    return <String, Map<String, Map<String, dynamic>>>{
      for (final MapEntry<String, Map<String, Map<String, dynamic>>> c
          in all.entries)
        if (allowsCollection(c.key))
          c.key: <String, Map<String, dynamic>>{
            for (final MapEntry<String, Map<String, dynamic>> r
                in c.value.entries)
              if (includes(c.key, r.value) ||
                  ledger[c.key]?.containsKey(r.key) == true)
                r.key: r.value,
          },
    };
  }

  /// [ledger] for this scope: the collections it syncs, every entry kept.
  ///
  /// Entries of known records stay even once they are older than the window
  /// ([local] keeps those records in the round), so nothing is read as
  /// deleted while it is still on the device. A collection the scope doesn't
  /// sync is dropped: its records are not in the round and would otherwise
  /// all look deleted.
  Entries pruneLedger(Entries ledger, Records all) {
    if (isFull) return ledger;
    return <String, Map<String, SyncEntry>>{
      for (final MapEntry<String, Map<String, SyncEntry>> c in ledger.entries)
        if (allowsCollection(c.key)) c.key: c.value,
    };
  }

  /// Whether the cloud entry [e] of record [id] takes part in the merge.
  ///
  /// Everything does (so a new device still receives the older history the
  /// cloud holds) except an old record this device holds outside the round:
  /// the cloud copy of it is not newer news, and writing it back over the
  /// device's copy undid the user's edits.
  bool _cloudCovered(
          String c, String id, SyncEntry e, Entries local, Records all) =>
      allowsCollection(c) &&
      (e.deleted ||
          includes(c, e.data!) ||
          local[c]?.containsKey(id) == true ||
          all[c]?.containsKey(id) != true);

  /// The cloud entries the round merges (see [_cloudCovered]). [all] is
  /// everything the device holds.
  Entries cloudIn(Entries cloud, Entries local, Records all) {
    if (isFull) return cloud;
    return <String, Map<String, SyncEntry>>{
      for (final MapEntry<String, Map<String, SyncEntry>> c in cloud.entries)
        if (allowsCollection(c.key))
          c.key: <String, SyncEntry>{
            for (final MapEntry<String, SyncEntry> e in c.value.entries)
              if (_cloudCovered(c.key, e.key, e.value, local, all))
                e.key: e.value,
          },
    };
  }

  /// The cloud entries the round leaves alone: sent back as they were. An
  /// old record this device doesn't sync is never written over the copy the
  /// device holds.
  Entries cloudHeld(Entries cloud, Entries local, Records all) {
    if (isFull) return const <String, Map<String, SyncEntry>>{};
    final Entries out = <String, Map<String, SyncEntry>>{};
    for (final MapEntry<String, Map<String, SyncEntry>> c in cloud.entries) {
      final Map<String, SyncEntry> kept = <String, SyncEntry>{
        for (final MapEntry<String, SyncEntry> e in c.value.entries)
          if (!_cloudCovered(c.key, e.key, e.value, local, all))
            e.key: e.value,
      };
      if (kept.isNotEmpty) out[c.key] = kept;
    }
    return out;
  }

  /// [merged] plus the [held] cloud entries, for the document to upload.
  /// Merged per record: a held entry never replaces a merged one.
  Entries withHeld(Entries merged, Entries held) {
    if (held.isEmpty) return merged;
    return <String, Map<String, SyncEntry>>{
      for (final String c in <String>{...held.keys, ...merged.keys})
        c: <String, SyncEntry>{...?held[c], ...?merged[c]},
    };
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
