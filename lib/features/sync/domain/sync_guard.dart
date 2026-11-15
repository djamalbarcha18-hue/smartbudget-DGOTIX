/// Safety checks between noticing this device's changes and sending them.
///
/// A deletion reaches every device and can't be taken back, so the round only
/// sends the ones it can trust. A record that is missing because it couldn't
/// be read, or a list that came back empty from storage, is not a deletion:
/// its cloud copy is merged back in instead.
library;

import 'package:smartbudget/features/sync/domain/sync_merge.dart';

abstract final class SyncGuard {
  /// A list the ledger knows with at least this many records that is now
  /// entirely empty is taken for a storage problem, not for the user
  /// deleting everything one by one.
  static const int emptiedListMinimum = 10;

  /// [local] (from SyncMerge.detect) without the deletions it can't trust:
  /// every new deletion when [readLoss] (something couldn't be read this
  /// session), and those of a list that was emptied all at once.
  ///
  /// A removed entry is simply absent, so the cloud's live copy wins the
  /// merge and the record comes back on this device.
  static Entries withoutSuspectDeletions(
    Entries ledger,
    Entries local, {
    required bool readLoss,
  }) {
    final Entries out = <String, Map<String, SyncEntry>>{};
    for (final MapEntry<String, Map<String, SyncEntry>> c in local.entries) {
      final Map<String, SyncEntry> before =
          ledger[c.key] ?? const <String, SyncEntry>{};
      bool isNewDeletion(String id, SyncEntry e) =>
          e.deleted && before[id] != null && !before[id]!.deleted;
      final int knownLive =
          before.values.where((SyncEntry e) => !e.deleted).length;
      final int liveNow =
          c.value.values.where((SyncEntry e) => !e.deleted).length;
      final bool emptied = knownLive >= emptiedListMinimum && liveNow == 0;
      out[c.key] = <String, SyncEntry>{
        for (final MapEntry<String, SyncEntry> e in c.value.entries)
          if (!((readLoss || emptied) && isNewDeletion(e.key, e.value)))
            e.key: e.value,
      };
    }
    return out;
  }

  /// [local] when the ledger itself couldn't be read: nothing is known about
  /// when the device's records changed, so they count as the oldest (time 0).
  /// Any newer edit or deletion in the cloud then wins, and records only this
  /// device has are still uploaded. Before, they all looked changed just now
  /// and overwrote newer edits from the other devices.
  static Entries untimed(Entries local) => <String, Map<String, SyncEntry>>{
        for (final MapEntry<String, Map<String, SyncEntry>> c in local.entries)
          c.key: <String, SyncEntry>{
            for (final MapEntry<String, SyncEntry> e in c.value.entries)
              e.key: e.value.deleted
                  ? e.value
                  : SyncEntry(t: 0, data: e.value.data, hash: e.value.hash),
          },
      };
}
