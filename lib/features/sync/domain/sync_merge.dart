/// Record-level sync between this device and the account's cloud copy.
///
/// Everything a backup holds (transactions, budgets, goals, wallets, custom
/// categories, the base currency...) is seen as collections of records keyed
/// by id. Each device keeps a ledger: for every record, when it last changed
/// here (or was deleted: a tombstone) and a fingerprint of its content. The
/// cloud copy holds the same entries with the records' data. Merging takes,
/// record by record, the newer entry, so an edit or a deletion made on one
/// device reaches the others and the newest change wins.
library;

import 'dart:convert';

/// One record's state: its data, or null when it was deleted.
class SyncEntry {
  const SyncEntry({required this.t, this.data, this.hash});

  /// When it last changed (milliseconds since epoch, device clock).
  final int t;

  /// The record (JSON); null for a deletion.
  final Map<String, dynamic>? data;

  /// Fingerprint of [data] as last seen on this device (ledger only).
  final String? hash;

  bool get deleted => data == null && hash == null;
}

/// collection -> id -> entry.
typedef Entries = Map<String, Map<String, SyncEntry>>;

/// collection -> id -> record JSON.
typedef Records = Map<String, Map<String, Map<String, dynamic>>>;

abstract final class SyncMerge {
  /// The collections that are lists of records with an `id`.
  static const List<String> listCollections = <String>[
    'transactions',
    'budgets',
    'goals',
    'debts',
    'projects',
    'recurring',
    'seasons',
    'darets',
    'challenges',
    'wallets',
    'walletMoves',
  ];

  /// Deletions are remembered this long, then forgotten.
  static const Duration tombstoneLife = Duration(days: 120);

  // ---- Records <-> backup JSON (BackupData.toJson) --------------------------

  /// The records in a backup's JSON: list collections by id, custom
  /// categories by name, the base currency as a single setting.
  static Records recordsFromBackup(Map<String, dynamic> json) {
    final Records out = <String, Map<String, Map<String, dynamic>>>{};
    for (final String c in listCollections) {
      final Map<String, Map<String, dynamic>> byId =
          <String, Map<String, dynamic>>{};
      final Object? list = json[c];
      if (list is List) {
        for (final Object? r in list) {
          if (r is Map && r['id'] is String && (r['id'] as String).isNotEmpty) {
            byId[r['id'] as String] = Map<String, dynamic>.from(r);
          }
        }
      }
      out[c] = byId;
    }
    final Object? cc = json['customCategories'];
    for (final String kind in <String>['income', 'expense']) {
      final Map<String, Map<String, dynamic>> byName =
          <String, Map<String, dynamic>>{};
      final Object? names = cc is Map ? cc[kind] : null;
      if (names is List) {
        for (final Object? n in names) {
          if (n is String && n.isNotEmpty) {
            byName[n] = <String, dynamic>{'name': n};
          }
        }
      }
      out['customCategories.$kind'] = byName;
    }
    final Object? base = json['baseCurrency'];
    out['settings'] = <String, Map<String, dynamic>>{
      if (base is String && base.isNotEmpty)
        'baseCurrency': <String, dynamic>{'value': base},
    };
    return out;
  }

  /// A backup JSON (for BackupData.fromJson) holding exactly [records].
  static Map<String, dynamic> backupFromRecords(Records records) {
    List<Map<String, dynamic>> listOf(String c) =>
        (records[c] ?? const <String, Map<String, dynamic>>{})
            .values
            .toList();
    List<String> namesOf(String c) =>
        (records[c] ?? const <String, Map<String, dynamic>>{}).keys.toList()
          ..sort();
    final Map<String, dynamic>? base = records['settings']?['baseCurrency'];
    return <String, dynamic>{
      'schemaVersion': 1,
      'app': 'SmartBudget',
      'exportedAt': DateTime.now().toIso8601String(),
      if (base != null) 'baseCurrency': base['value'],
      for (final String c in listCollections) c: listOf(c),
      'customCategories': <String, dynamic>{
        'income': namesOf('customCategories.income'),
        'expense': namesOf('customCategories.expense'),
      },
    };
  }

  // ---- Change detection --------------------------------------------------

  /// A stable fingerprint of a record (keys sorted at every level).
  static String fingerprint(Map<String, dynamic> record) {
    Object? canon(Object? v) {
      if (v is Map) {
        final List<String> keys = v.keys.map((Object? k) => '$k').toList()
          ..sort();
        return <String, Object?>{for (final String k in keys) k: canon(v[k])};
      }
      if (v is List) return v.map(canon).toList();
      return v;
    }

    final String s = jsonEncode(canon(record));
    // FNV-1a, 64-bit in two 32-bit halves: short and good enough to notice
    // a change.
    int h1 = 0x811c9dc5, h2 = 0x01000193;
    for (final int u in utf8.encode(s)) {
      h1 = ((h1 ^ u) * 0x01000193) & 0xffffffff;
      h2 = ((h2 ^ u) * 0x811c9dc5) & 0xffffffff;
    }
    return '${h1.toRadixString(36)}${h2.toRadixString(36)}:${s.length}';
  }

  /// The ledger after looking at the device's current [records]: a record
  /// that is new or changed gets time [now]; one that disappeared becomes a
  /// deletion at [now]. Data is attached to every live entry.
  static Entries detect(Entries ledger, Records records, int now) {
    final Entries out = <String, Map<String, SyncEntry>>{};
    final Set<String> collections = <String>{...ledger.keys, ...records.keys};
    for (final String c in collections) {
      final Map<String, SyncEntry> before =
          ledger[c] ?? const <String, SyncEntry>{};
      final Map<String, Map<String, dynamic>> current =
          records[c] ?? const <String, Map<String, dynamic>>{};
      final Map<String, SyncEntry> next = <String, SyncEntry>{};
      for (final MapEntry<String, Map<String, dynamic>> r in current.entries) {
        final String h = fingerprint(r.value);
        final SyncEntry? old = before[r.key];
        final bool same = old != null && !old.deleted && old.hash == h;
        next[r.key] = SyncEntry(t: same ? old.t : now, data: r.value, hash: h);
      }
      for (final MapEntry<String, SyncEntry> o in before.entries) {
        if (current.containsKey(o.key)) continue;
        next[o.key] =
            o.value.deleted ? o.value : SyncEntry(t: now); // just deleted
      }
      out[c] = next;
    }
    return out;
  }

  // ---- Merge ---------------------------------------------------------------

  /// Record by record, the newer of [local] and [remote]. A tie keeps a
  /// deletion, else the larger fingerprint, so every device settles on the
  /// same result. Budgets for the same category and month made on two devices
  /// become one (the newest). Deletions older than [tombstoneLife] are
  /// dropped.
  static Entries merge(Entries local, Entries remote, {required int now}) {
    final Entries out = <String, Map<String, SyncEntry>>{};
    for (final String c in <String>{...local.keys, ...remote.keys}) {
      final Map<String, SyncEntry> a = local[c] ?? const <String, SyncEntry>{};
      final Map<String, SyncEntry> b =
          remote[c] ?? const <String, SyncEntry>{};
      final Map<String, SyncEntry> next = <String, SyncEntry>{};
      for (final String id in <String>{...a.keys, ...b.keys}) {
        final SyncEntry? x = a[id], y = b[id];
        next[id] = x == null
            ? _withHash(y!)
            : y == null
                ? x
                : _newer(x, y);
      }
      out[c] = next;
    }
    _oneBudgetPerCategoryMonth(out);
    final int cutoff = now - tombstoneLife.inMilliseconds;
    for (final Map<String, SyncEntry> m in out.values) {
      m.removeWhere((String _, SyncEntry e) => e.deleted && e.t < cutoff);
    }
    return out;
  }

  static SyncEntry _withHash(SyncEntry e) => e.deleted || e.hash != null
      ? e
      : SyncEntry(t: e.t, data: e.data, hash: fingerprint(e.data!));

  static SyncEntry _newer(SyncEntry x, SyncEntry y) =>
      _beats(x, y) ? _withHash(x) : _withHash(y);

  /// Whether [x] wins over [y]: newer, else a deletion, else the larger
  /// fingerprint (so every device picks the same one).
  static bool _beats(SyncEntry x, SyncEntry y) {
    if (x.t != y.t) return x.t > y.t;
    if (x.deleted || y.deleted) return x.deleted;
    return _withHash(x).hash!.compareTo(_withHash(y).hash!) >= 0;
  }

  static void _oneBudgetPerCategoryMonth(Entries entries) {
    final Map<String, SyncEntry>? budgets = entries['budgets'];
    if (budgets == null) return;
    final Map<String, String> winner = <String, String>{};
    String keyOf(Map<String, dynamic> d) =>
        '${d['year']}-${d['month']}-${d['category']}';
    for (final MapEntry<String, SyncEntry> e in budgets.entries) {
      if (e.value.deleted) continue;
      final String k = keyOf(e.value.data!);
      final String? w = winner[k];
      if (w == null || _beats(e.value, budgets[w]!)) {
        winner[k] = e.key;
      }
    }
    final Set<String> keep = winner.values.toSet();
    for (final String id in budgets.keys.toList()) {
      final SyncEntry e = budgets[id]!;
      if (e.deleted || keep.contains(id)) continue;
      final SyncEntry w = budgets[winner[keyOf(e.data!)]!]!;
      budgets[id] = SyncEntry(t: w.t);
    }
  }

  /// [merged] after its records were written to the device and read back:
  /// the same times, with the fingerprints (and data) of what is actually
  /// stored, so storing a record in its normal form isn't taken for an edit.
  static Entries rebase(Entries merged, Records stored) =>
      <String, Map<String, SyncEntry>>{
        for (final MapEntry<String, Map<String, SyncEntry>> c
            in merged.entries)
          c.key: <String, SyncEntry>{
            for (final MapEntry<String, SyncEntry> e in c.value.entries)
              e.key: e.value.deleted || stored[c.key]?[e.key] == null
                  ? e.value
                  : SyncEntry(
                      t: e.value.t,
                      data: stored[c.key]![e.key],
                      hash: fingerprint(stored[c.key]![e.key]!)),
          },
      };

  /// The live records of [entries].
  static Records recordsOf(Entries entries) => <String, Map<String, Map<String, dynamic>>>{
        for (final MapEntry<String, Map<String, SyncEntry>> c in entries.entries)
          c.key: <String, Map<String, dynamic>>{
            for (final MapEntry<String, SyncEntry> e in c.value.entries)
              if (!e.value.deleted) e.key: e.value.data!,
          },
      };

  /// Whether two sets of records hold the same content.
  static bool sameRecords(Records a, Records b) {
    String sig(Records r) {
      final List<String> parts = <String>[];
      for (final String c in r.keys.toList()..sort()) {
        for (final String id in r[c]!.keys.toList()..sort()) {
          parts.add('$c/$id/${fingerprint(r[c]![id]!)}');
        }
      }
      return parts.join('|');
    }

    return sig(a) == sig(b);
  }

  /// Whether two sets of entries hold the same records and deletions.
  static bool same(Entries a, Entries b) {
    String sig(Entries e) {
      final List<String> parts = <String>[];
      for (final String c in e.keys.toList()..sort()) {
        for (final String id in e[c]!.keys.toList()..sort()) {
          final SyncEntry x = _withHash(e[c]![id]!);
          parts.add('$c/$id/${x.t}/${x.deleted ? 'x' : x.hash}');
        }
      }
      return parts.join('|');
    }

    return sig(a) == sig(b);
  }

  // ---- Stored forms ------------------------------------------------------

  /// The cloud document for [entries] (data included).
  static Map<String, dynamic> toCloud(Entries entries) => <String, dynamic>{
        'format': 'sb-sync',
        'v': 2,
        'c': <String, dynamic>{
          for (final MapEntry<String, Map<String, SyncEntry>> c
              in entries.entries)
            c.key: <String, dynamic>{
              for (final MapEntry<String, SyncEntry> e in c.value.entries)
                e.key: e.value.deleted
                    ? <String, dynamic>{'t': e.value.t, 'x': 1}
                    : <String, dynamic>{'t': e.value.t, 'd': e.value.data},
            },
        },
      };

  /// Entries from a cloud document. A plain backup (older app versions)
  /// counts as records changed at time 0, so any newer change wins over it.
  static Entries fromCloud(Map<String, dynamic>? doc) {
    if (doc == null) return <String, Map<String, SyncEntry>>{};
    if (doc['format'] != 'sb-sync') {
      final Records r = recordsFromBackup(doc);
      return <String, Map<String, SyncEntry>>{
        for (final MapEntry<String, Map<String, Map<String, dynamic>>> c
            in r.entries)
          c.key: <String, SyncEntry>{
            for (final MapEntry<String, Map<String, dynamic>> e
                in c.value.entries)
              e.key: SyncEntry(t: 0, data: e.value),
          },
      };
    }
    final Entries out = <String, Map<String, SyncEntry>>{};
    final Object? cs = doc['c'];
    if (cs is! Map) return out;
    cs.forEach((Object? c, Object? items) {
      if (c is! String || items is! Map) return;
      final Map<String, SyncEntry> m = <String, SyncEntry>{};
      items.forEach((Object? id, Object? v) {
        if (id is! String || v is! Map || v['t'] is! num) return;
        final int t = (v['t'] as num).toInt();
        final Object? d = v['d'];
        if (v['x'] == 1) {
          m[id] = SyncEntry(t: t);
        } else if (d is Map) {
          m[id] = SyncEntry(t: t, data: Map<String, dynamic>.from(d));
        }
      });
      out[c] = m;
    });
    return out;
  }

  /// The ledger kept on the device: times and fingerprints, no data.
  static Map<String, dynamic> ledgerToJson(Entries entries) =>
      <String, dynamic>{
        for (final MapEntry<String, Map<String, SyncEntry>> c
            in entries.entries)
          c.key: <String, dynamic>{
            for (final MapEntry<String, SyncEntry> e in c.value.entries)
              e.key: e.value.deleted
                  ? <String, dynamic>{'t': e.value.t}
                  : <String, dynamic>{
                      't': e.value.t,
                      'h': _withHash(e.value).hash,
                    },
          },
      };

  static Entries ledgerFromJson(Map<String, dynamic>? json) {
    final Entries out = <String, Map<String, SyncEntry>>{};
    json?.forEach((String c, Object? items) {
      if (items is! Map) return;
      final Map<String, SyncEntry> m = <String, SyncEntry>{};
      items.forEach((Object? id, Object? v) {
        if (id is String && v is Map && v['t'] is num) {
          m[id] = SyncEntry(
              t: (v['t'] as num).toInt(), hash: v['h'] as String?);
        }
      });
      out[c] = m;
    });
    return out;
  }
}
