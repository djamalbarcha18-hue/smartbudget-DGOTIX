import 'dart:async';
import 'dart:convert';

import 'package:idb_shim/idb.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/record_lists.dart';
import 'package:smartbudget/core/storage/stored_list.dart';

/// One step of the database's layout: brings version `i` to `i + 1`.
typedef LocalDbStep = void Function(Database db, Transaction txn);

/// The user's lists in the device database (IndexedDB on the web), each
/// record on its own row, so a change writes that record only.
///
/// Safety, list by list:
/// - **Moving in.** The first time a list is opened its SharedPreferences
///   copy is copied in, read back and compared (count, ids, every record,
///   the amounts per currency) before the database is used for it. Anything
///   different and the list stays where it was; the next start tries again.
///   Copying again never doubles a record (rows are keyed by id).
/// - **The old copy stays.** SharedPreferences is never cleared; with
///   [mirror] every save is also written there, so turning the database off
///   loses nothing ([restoreToPrefs] covers a mirror that fell behind).
/// - **Failures are said.** A save the database refuses throws (the app
///   shows it, see SaveHealth). A database that can't be opened, or a list
///   that can't be moved in, means SharedPreferences for that list, as before.
/// - **Unreadable records** are copied to a quarantine store, never dropped
///   silently.
/// - **Newer versions** of the app in another tab: this tab's connection
///   closes so their upgrade isn't blocked; saves here then fail visibly
///   until a reload.
///
/// Rows carry the list's key (`sb_txns_<account>`...), so accounts stay
/// apart exactly as in SharedPreferences, and removing an account from the
/// device removes its rows ([forget]). Nothing here is a secret: no
/// passwords, tokens or PIN are ever stored in it.
class LocalDbRecordLists implements RecordLists {
  LocalDbRecordLists(
    this._factory, {
    this.name = dbName,
    this.mirror = true,
    List<LocalDbStep>? steps,
  }) : steps = steps ?? schema;

  static const String dbName = 'smartbudget';

  /// Set once a list has been moved in (device-wide; see [restoreToPrefs]).
  static const String usedKey = 'sb_localdb_used';

  /// Lists last saved without the database, to be moved in again.
  static const String redoKey = 'sb_localdb_redo';

  static const String _records = 'records';
  static const String _meta = 'meta';
  static const String _quarantine = 'quarantine';

  /// The layout, version by version. A released step never changes; a new
  /// layout is a new step.
  static final List<LocalDbStep> schema = <LocalDbStep>[_v1];

  static void _v1(Database db, Transaction txn) {
    db.createObjectStore(_records).createIndex('list', 'list');
    db.createObjectStore(_meta);
    db.createObjectStore(_quarantine, autoIncrement: true);
  }

  final IdbFactory _factory;
  final String name;
  final bool mirror;
  final List<LocalDbStep> steps;

  static const PrefsRecordLists _prefs = PrefsRecordLists();

  Future<Database?>? _opening;
  bool _closed = false;

  /// Lists kept in SharedPreferences for this session (couldn't be moved in).
  final Set<String> _prefsOnly = <String>{};

  /// Per list: id -> (order, canonical JSON) as last read or written.
  final Map<String, Map<String, _Known>> _known =
      <String, Map<String, _Known>>{};

  /// Per list: whether the SharedPreferences copy was last written too.
  final Map<String, bool> _mirrored = <String, bool>{};

  /// Why the database or a list isn't used (shown in tests and reports).
  Object? lastProblem;

  /// Whether [key] is kept in the database (false: SharedPreferences).
  bool usesDatabaseFor(String key) =>
      !_prefsOnly.contains(key) && _known.containsKey(key);

  // ---- Opening -----------------------------------------------------------

  Future<Database?> _open() => _opening ??= _openNow();

  Future<Database?> _openNow() async {
    try {
      final Database db = await _factory.open(
        name,
        version: steps.length,
        onUpgradeNeeded: (VersionChangeEvent e) {
          for (int v = e.oldVersion; v < e.newVersion; v++) {
            steps[v](e.database, e.transaction);
          }
        },
      );
      // A newer version of the app wants to upgrade: let it.
      db.onVersionChange.listen((_) {
        _closed = true;
        db.close();
      });
      return db;
    } catch (e) {
      lastProblem = e;
      return null;
    }
  }

  /// Closes the connection (tests; the browser closes it with the page).
  Future<void> close() async {
    final Database? db = await _opening;
    _closed = true;
    db?.close();
  }

  // ---- Reading and saving --------------------------------------------------

  @override
  Future<List<T>> load<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final Database? db = await _open();
    if (db == null || _closed || !await _ready(db, key)) {
      _prefsOnly.add(key);
      return _prefs.load(key, fromJson);
    }
    final List<_Row> rows;
    try {
      rows = await _rows(db, key);
    } catch (e) {
      lastProblem = e;
      _prefsOnly.add(key);
      return _prefs.load(key, fromJson);
    }
    final List<T> out = <T>[];
    final List<_Row> unreadable = <_Row>[];
    for (final _Row r in rows) {
      try {
        out.add(fromJson(r.data));
      } catch (_) {
        unreadable.add(r);
      }
    }
    _known[key] = <String, _Known>{
      for (final _Row r in rows) r.id: _Known(r.seq, _canon(r.data)),
    };
    if (unreadable.isNotEmpty) await _setAside(db, key, unreadable);
    return out;
  }

  @override
  Future<void> save(String key, List<Map<String, dynamic>> records) async {
    if (_prefsOnly.contains(key)) return _savePrefsOnly(key, records);
    final Database? db = await _open();
    if (db == null) {
      _prefsOnly.add(key);
      return _savePrefsOnly(key, records);
    }
    if (_closed) throw StateError('database closed for an upgrade');
    if (!await _ready(db, key)) {
      _prefsOnly.add(key);
      return _savePrefsOnly(key, records);
    }
    final Map<String, _Known> known =
        _known[key] ?? await _knownFromDb(db, key);
    final List<String> ids = _ids(records);
    int next =
        known.values.fold<int>(-1, (int m, _Known k) => k.seq > m ? k.seq : m) +
            1;
    final Map<String, _Known> now = <String, _Known>{};
    final Transaction txn = db.transaction(_records, idbModeReadWrite);
    final ObjectStore store = txn.objectStore(_records);
    final List<Future<Object?>> ops = <Future<Object?>>[];
    for (int i = 0; i < records.length; i++) {
      final String id = ids[i];
      final String canon = _canon(records[i]);
      final _Known? before = known[id];
      final int seq = before?.seq ?? next++;
      now[id] = _Known(seq, canon);
      if (before?.canon != canon) {
        ops.add(
            store.put(_rowValue(key, id, seq, records[i]), _rowKey(key, id)));
      }
    }
    for (final String id in known.keys) {
      if (!now.containsKey(id)) ops.add(store.delete(_rowKey(key, id)));
    }
    await _finish(txn, ops);
    _known[key] = now;
    await _mirror(db, key, records);
  }

  /// A save that went to SharedPreferences only (no database this time):
  /// that copy is now the newer one, so the list is moved in again from it
  /// next time instead of the database's older rows being used.
  Future<void> _savePrefsOnly(
      String key, List<Map<String, dynamic>> records) async {
    await _prefs.save(key, records);
    final SharedPreferences p = await SharedPreferences.getInstance();
    final List<String> redo = p.getStringList(redoKey) ?? <String>[];
    if (!redo.contains(key)) {
      await p.setStringList(redoKey, <String>[...redo, key]);
    }
  }

  /// The old SharedPreferences copy, kept equal while it fits ([mirror]);
  /// when it isn't written the list is marked, so that turning the database
  /// off first copies it back ([restoreToPrefs]).
  Future<void> _mirror(
      Database db, String key, List<Map<String, dynamic>> records) async {
    bool ok = false;
    if (mirror) {
      try {
        final SharedPreferences p = await SharedPreferences.getInstance();
        ok = await p.setString(key, jsonEncode(records));
      } catch (_) {
        ok = false;
      }
    }
    if (_mirrored[key] == ok) return;
    _mirrored[key] = ok;
    try {
      final Transaction txn = db.transaction(_meta, idbModeReadWrite);
      final ObjectStore meta = txn.objectStore(_meta);
      final Object? m = await meta.getObject(key);
      if (m is Map && m['mirror'] != ok) {
        await meta.put(
            <String, Object?>{...m.cast<String, Object?>(), 'mirror': ok}, key);
      }
      await txn.completed;
    } catch (_) {
      _mirrored.remove(key); // marked on the next save
    }
  }

  // ---- Moving a list in ------------------------------------------------------

  /// Whether [key] is in the database, moving it in first if needed.
  Future<bool> _ready(Database db, String key) async {
    if (_known.containsKey(key)) return true;
    try {
      final Transaction t = db.transaction(_meta, idbModeReadOnly);
      final Object? m = await t.objectStore(_meta).getObject(key);
      await t.completed;
      final SharedPreferences p = await SharedPreferences.getInstance();
      final List<String> redo = p.getStringList(redoKey) ?? <String>[];
      if (m is Map && m['state'] == 'ready' && !redo.contains(key)) {
        return true;
      }
      if (!await _moveIn(db, key)) return false;
      if (redo.contains(key)) {
        await p.setStringList(redoKey, <String>[
          for (final String k in redo)
            if (k != key) k
        ]);
      }
      return true;
    } catch (e) {
      lastProblem = e;
      return false;
    }
  }

  Future<bool> _moveIn(Database db, String key) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String? raw = p.getString(key);
    final List<Map<String, dynamic>> source = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (e) {
        lastProblem = e;
        return false; // the old reader keeps it aside
      }
      if (decoded is! List) return false;
      bool lost = false;
      for (final Object? e in decoded) {
        if (e is Map) {
          source.add(Map<String, dynamic>.from(e));
        } else {
          lost = true;
        }
      }
      if (lost) StoredList.keepAside(p, key, raw);
    }
    // Records with no id or a shared one are kept by position (_ids).
    final List<String> ids = _ids(source);

    // Copy (over anything a broken earlier attempt left).
    final Transaction txn = db.transaction(_records, idbModeReadWrite);
    final ObjectStore store = txn.objectStore(_records);
    final List<Future<Object?>> ops = <Future<Object?>>[
      for (final Object k in await store.index('list').getAllKeys(key))
        store.delete(k),
      for (int i = 0; i < source.length; i++)
        store.put(_rowValue(key, ids[i], i, source[i]), _rowKey(key, ids[i])),
    ];
    try {
      await _finish(txn, ops);
    } catch (e) {
      lastProblem = e; // e.g. no room: stays where it was
      return false;
    }

    // Read back and compare before trusting it.
    final List<_Row> rows = await _rows(db, key);
    final String? mismatch = _verify(source, ids, rows);
    if (mismatch != null) {
      lastProblem = StateError('$key: $mismatch');
      final Transaction undo = db.transaction(_records, idbModeReadWrite);
      await _finish(undo, <Future<Object?>>[
        for (final _Row r in rows)
          undo.objectStore(_records).delete(_rowKey(key, r.id)),
      ]);
      return false;
    }
    final Transaction done = db.transaction(_meta, idbModeReadWrite);
    await _finish(done, <Future<Object?>>[
      done.objectStore(_meta).put(<String, Object?>{
        'state': 'ready',
        'count': source.length,
        'sums': _sums(source),
        'at': DateTime.now().toUtc().toIso8601String(),
        'mirror': true,
      }, key),
    ]);
    await p.setBool(usedKey, true);
    return true;
  }

  /// Null when [rows] hold exactly [source]; else what differs.
  static String? _verify(
      List<Map<String, dynamic>> source, List<String> ids, List<_Row> rows) {
    if (rows.length != source.length) {
      return 'count ${rows.length} != ${source.length}';
    }
    final Map<String, _Row> byId = <String, _Row>{
      for (final _Row r in rows) r.id: r,
    };
    for (int i = 0; i < source.length; i++) {
      final _Row? r = byId[ids[i]];
      if (r == null) return 'missing ${ids[i]}';
      if (_canon(r.data) != _canon(source[i])) return 'changed ${ids[i]}';
    }
    final String a = jsonEncode(_sums(source));
    final String b = jsonEncode(_sums(<Map<String, dynamic>>[
      for (final _Row r in rows) r.data,
    ]));
    return a == b ? null : 'amounts $b != $a';
  }

  // ---- Accounts --------------------------------------------------------------

  @override
  Future<void> forget(bool Function(String key) which) async {
    final Database? db = await _open();
    if (db == null || _closed) return;
    final Transaction txn = db.transactionList(
        <String>[_records, _meta, _quarantine], idbModeReadWrite);
    final ObjectStore meta = txn.objectStore(_meta);
    final ObjectStore records = txn.objectStore(_records);
    final List<String> keys = <String>[
      for (final Object k in await meta.getAllKeys())
        if (k is String && which(k)) k,
    ];
    final List<Future<Object?>> ops = <Future<Object?>>[];
    for (final String key in keys) {
      for (final Object k in await records.index('list').getAllKeys(key)) {
        ops.add(records.delete(k));
      }
      ops.add(meta.delete(key));
      _known.remove(key);
    }
    final ObjectStore q = txn.objectStore(_quarantine);
    final List<Object> qKeys = await q.getAllKeys();
    final List<Object> qValues = await q.getAll();
    for (int i = 0; i < qKeys.length && i < qValues.length; i++) {
      final Object v = qValues[i];
      if (v is Map && v['list'] is String && which(v['list'] as String)) {
        ops.add(q.delete(qKeys[i]));
      }
    }
    await _finish(txn, ops);
  }

  @override
  Future<void> move(String from, String to) async {
    final Database? db = await _open();
    if (db == null || _closed) return;
    final Transaction txn =
        db.transactionList(<String>[_records, _meta], idbModeReadWrite);
    final ObjectStore meta = txn.objectStore(_meta);
    final ObjectStore records = txn.objectStore(_records);
    final Object? fromMeta = await meta.getObject(from);
    final Object? toMeta = await meta.getObject(to);
    final List<Object> rows = await records.index('list').getAll(from);
    final List<Future<Object?>> ops = <Future<Object?>>[
      for (final Object k in await records.index('list').getAllKeys(from))
        records.delete(k),
      meta.delete(from),
    ];
    if (toMeta == null && fromMeta != null) {
      for (final Object v in rows) {
        if (v is! Map) continue;
        final _Row r = _Row.of(v);
        ops.add(
            records.put(_rowValue(to, r.id, r.seq, r.data), _rowKey(to, r.id)));
      }
      ops.add(meta.put(fromMeta, to));
    }
    await _finish(txn, ops);
    _known
      ..remove(from)
      ..remove(to);
  }

  // ---- Turning it off ----------------------------------------------------------

  /// Before running without the database again: copies back every list whose
  /// SharedPreferences copy fell behind, then empties the database, so that
  /// turning it on later moves the lists in afresh. True when all is back.
  static Future<bool> restoreToPrefs(IdbFactory factory,
      {String name = dbName}) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    if (p.getBool(usedKey) != true) return true;
    final Database db;
    try {
      db = await factory.open(name);
    } catch (_) {
      return false;
    }
    try {
      if (!db.objectStoreNames.contains(_meta)) {
        await p.remove(usedKey);
        return true;
      }
      final Transaction read =
          db.transactionList(<String>[_records, _meta], idbModeReadOnly);
      final ObjectStore meta = read.objectStore(_meta);
      final Map<String, List<Map<String, dynamic>>> behind =
          <String, List<Map<String, dynamic>>>{};
      for (final Object k in await meta.getAllKeys()) {
        final Object? m = await meta.getObject(k);
        if (k is String && m is Map && m['mirror'] != true) {
          final List<_Row> rows = <_Row>[
            for (final Object v
                in await read.objectStore(_records).index('list').getAll(k))
              if (v is Map) _Row.of(v),
          ]..sort((_Row a, _Row b) => a.seq.compareTo(b.seq));
          behind[k] = <Map<String, dynamic>>[for (final _Row r in rows) r.data];
        }
      }
      await read.completed;
      for (final MapEntry<String, List<Map<String, dynamic>>> e
          in behind.entries) {
        if (!await p.setString(e.key, jsonEncode(e.value))) return false;
      }
      final Transaction clear =
          db.transactionList(<String>[_records, _meta], idbModeReadWrite);
      await clear.objectStore(_records).clear();
      await clear.objectStore(_meta).clear();
      await clear.completed;
      await p.remove(usedKey);
      await p.remove(redoKey);
      return true;
    } catch (_) {
      return false;
    } finally {
      db.close();
    }
  }

  // ---- Helpers -------------------------------------------------------------------

  /// Waits for [ops] and the end of [txn]; the first failure is thrown, and
  /// every other one is handled (none goes unseen).
  static Future<void> _finish(
      Transaction txn, List<Future<Object?>> ops) async {
    Object? error;
    for (final Future<Object?> op in ops) {
      try {
        await op;
      } catch (e) {
        error ??= e;
      }
    }
    try {
      await txn.completed;
    } catch (e) {
      error ??= e;
    }
    if (error != null) throw error;
  }

  Future<List<_Row>> _rows(Database db, String key) async {
    final Transaction t = db.transaction(_records, idbModeReadOnly);
    final List<Object> values =
        await t.objectStore(_records).index('list').getAll(key);
    await t.completed;
    final List<_Row> rows = <_Row>[];
    final List<Object> odd = <Object>[];
    for (final Object v in values) {
      if (v is Map && v['id'] is String && v['data'] is Map) {
        rows.add(_Row.of(v));
      } else {
        odd.add(v);
      }
    }
    if (odd.isNotEmpty) {
      final Transaction q = db.transaction(_quarantine, idbModeReadWrite);
      await _finish(q, <Future<Object?>>[
        for (final Object v in odd)
          q.objectStore(_quarantine).add(<String, Object?>{
            'list': key,
            'raw': v.toString(),
            'at': DateTime.now().toUtc().toIso8601String(),
          }),
      ]);
    }
    rows.sort((_Row a, _Row b) => a.seq.compareTo(b.seq));
    return rows;
  }

  Future<Map<String, _Known>> _knownFromDb(Database db, String key) async =>
      <String, _Known>{
        for (final _Row r in await _rows(db, key))
          r.id: _Known(r.seq, _canon(r.data)),
      };

  Future<void> _setAside(Database db, String key, List<_Row> rows) async {
    try {
      final Transaction q = db.transaction(_quarantine, idbModeReadWrite);
      await _finish(q, <Future<Object?>>[
        for (final _Row r in rows)
          q.objectStore(_quarantine).add(<String, Object?>{
            'list': key,
            'id': r.id,
            'data': r.data,
            'at': DateTime.now().toUtc().toIso8601String(),
          }),
      ]);
    } catch (_) {
      // The row itself stays until the list is saved again.
    }
  }

  /// Each record's id; positions when some have none or share one.
  static List<String> _ids(List<Map<String, dynamic>> records) {
    final List<String> ids = <String>[
      for (final Map<String, dynamic> r in records)
        r['id'] is String && (r['id'] as String).isNotEmpty
            ? r['id'] as String
            : '',
    ];
    if (ids.contains('') || ids.toSet().length != ids.length) {
      return <String>[for (int i = 0; i < records.length; i++) '#$i'];
    }
    return ids;
  }

  static String _rowKey(String list, String id) => '$list\n$id';

  static Map<String, Object?> _rowValue(
          String list, String id, int seq, Map<String, dynamic> data) =>
      <String, Object?>{'list': list, 'id': id, 'seq': seq, 'data': data};

  /// JSON with the keys sorted at every level.
  static String _canon(Object? v) {
    Object? sort(Object? x) {
      if (x is Map) {
        final List<String> keys = x.keys.map((Object? k) => '$k').toList()
          ..sort();
        return <String, Object?>{for (final String k in keys) k: sort(x[k])};
      }
      if (x is List) return x.map(sort).toList();
      return x;
    }

    return jsonEncode(sort(v));
  }

  /// Amounts (`...Minor` fields) added up per field and currency.
  static Map<String, num> _sums(List<Map<String, dynamic>> records) {
    final Map<String, num> out = <String, num>{};
    for (final Map<String, dynamic> r in records) {
      r.forEach((String k, Object? v) {
        if (k.endsWith('Minor') && v is num) {
          final String at = '$k/${r['currency'] ?? ''}';
          out[at] = (out[at] ?? 0) + v;
        }
      });
    }
    return Map<String, num>.fromEntries(
        out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}

class _Known {
  const _Known(this.seq, this.canon);
  final int seq;
  final String canon;
}

class _Row {
  const _Row(this.id, this.seq, this.data);

  factory _Row.of(Map<dynamic, dynamic> v) => _Row(
        v['id'] as String,
        (v['seq'] as num?)?.toInt() ?? 0,
        Map<String, dynamic>.from(v['data'] as Map),
      );

  final String id;
  final int seq;
  final Map<String, dynamic> data;
}
