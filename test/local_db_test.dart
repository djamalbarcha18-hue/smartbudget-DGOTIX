import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb.dart' as idb;
import 'package:idb_shim/idb_client_memory.dart' show newIdbFactoryMemory;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/local_db.dart';
import 'package:smartbudget/core/storage/local_list_store.dart';
import 'package:smartbudget/core/storage/record_lists.dart';
import 'package:smartbudget/core/storage/record_lists_setup.dart';
import 'package:smartbudget/core/storage/save_health.dart';
import 'package:smartbudget/features/account/application/account_deletion.dart';
import 'package:smartbudget/features/transactions/data/fake_transaction_repository.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

const String _u1 = '11111111-1111-4111-8111-111111111111';
const String _u2 = '22222222-2222-4222-8222-222222222222';

Map<String, dynamic> _t(String id, int minor, {String currency = 'DZD'}) =>
    <String, dynamic>{
      'id': id,
      'date': '2026-10-0${1 + id.codeUnitAt(0) % 9}T00:00:00.000',
      'type': 'expense',
      'category': 'المطاعم',
      'amountMinor': minor,
      'currency': currency,
      'description': 'meal $id',
      'paymentMethod': null,
      'notes': null,
      'walletId': null,
      'createdAt': '2026-10-20T12:00:00.000',
    };

Transaction _txn(String id, int minor) => Transaction.fromJson(_t(id, minor));

/// The rows of [list] as the database holds them (read straight from it).
Future<Map<String, Map<String, dynamic>>> _rows(
    idb.IdbFactory f, String list) async {
  final idb.Database db = await f.open(LocalDbRecordLists.dbName);
  final idb.Transaction t = db.transaction('records', idb.idbModeReadOnly);
  final List<Object> values =
      await t.objectStore('records').index('list').getAll(list);
  await t.completed;
  db.close();
  return <String, Map<String, dynamic>>{
    for (final Object v in values)
      (v as Map)['id'] as String: Map<String, dynamic>.from(v['data'] as Map),
  };
}

Future<String?> _pref(String key) async {
  final SharedPreferences p = await SharedPreferences.getInstance();
  return p.getString(key);
}

Future<List<String>> _ids(String userId) async {
  final FakeTransactionRepository repo =
      FakeTransactionRepository(userId: userId);
  await repo.watchAll().first;
  final List<String> ids = <String>[
    for (final Transaction t in repo.current) t.id,
  ];
  return ids..sort();
}

void main() {
  late idb.IdbFactory factory;
  late LocalDbRecordLists db;

  setUp(() {
    SharedPreferences.resetStatic();
    SaveHealth.reset();
    factory = newIdbFactoryMemory();
    db = LocalDbRecordLists(factory);
    RecordLists.current = db;
  });

  tearDown(() async {
    await db.close();
    RecordLists.current = const PrefsRecordLists();
  });

  void seed(Map<String, Object> values) =>
      SharedPreferences.setMockInitialValues(values);

  group('moving a list in', () {
    test('copied, compared, and the old copy left untouched', () async {
      final String old = jsonEncode(<Object>[
        _t('a', 4550),
        _t('b', 120000),
        _t('c', 99, currency: 'EUR'),
      ]);
      seed(<String, Object>{'sb_txns_$_u1': old});
      expect(await _ids(_u1), <String>['a', 'b', 'c']);
      expect(db.usesDatabaseFor('sb_txns_$_u1'), isTrue);
      final Map<String, Map<String, dynamic>> rows =
          await _rows(factory, 'sb_txns_$_u1');
      expect(rows.keys, unorderedEquals(<String>['a', 'b', 'c']));
      expect(rows['b']!['amountMinor'], 120000);
      expect(rows['c']!['currency'], 'EUR');
      expect(await _pref('sb_txns_$_u1'), old); // the old copy is kept
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getBool(LocalDbRecordLists.usedKey), isTrue);
    });

    test('fields this version does not know are kept as they are', () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[
          <String, dynamic>{
            ..._t('a', 1),
            'futureField': <int>[1, 2]
          },
        ]),
      });
      await _ids(_u1);
      expect((await _rows(factory, 'sb_txns_$_u1'))['a']!['futureField'],
          <int>[1, 2]);
    });

    test('moving in again never doubles a record', () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1), _t('b', 2)]),
      });
      await _ids(_u1);
      await db.close();
      // As if the app stopped after the copy, before it was marked done.
      final idb.Database raw = await factory.open(LocalDbRecordLists.dbName);
      final idb.Transaction t = raw.transaction('meta', idb.idbModeReadWrite);
      await t.objectStore('meta').delete('sb_txns_$_u1');
      await t.completed;
      raw.close();
      db = LocalDbRecordLists(factory);
      RecordLists.current = db;
      expect(await _ids(_u1), <String>['a', 'b']);
      expect((await _rows(factory, 'sb_txns_$_u1')).length, 2);
    });

    test('records sharing an id are both kept (by position)', () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1), _t('a', 2)]),
      });
      expect((await _ids(_u1)).length, 2);
      expect(db.usesDatabaseFor('sb_txns_$_u1'), isTrue);
      expect(await _rows(factory, 'sb_txns_$_u1'), hasLength(2));
    });

    test('an old copy that can\'t be read stays where it was', () async {
      seed(<String, Object>{'sb_txns_$_u1': '{not json'});
      expect(await _ids(_u1), isEmpty);
      expect(db.usesDatabaseFor('sb_txns_$_u1'), isFalse);
      expect(await _rows(factory, 'sb_txns_$_u1'), isEmpty);
      // Kept aside by the old reader, as before.
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getString('sb_unreadable_txns_$_u1'), '{not json');
    });

    test('a session without the database: moved in again from the newer copy',
        () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1)])
      });
      expect(await _ids(_u1), <String>['a']);
      await db.close();
      // Next start, the database can't be opened: the edit goes to the old
      // copy only.
      db = LocalDbRecordLists(_BrokenFactory());
      RecordLists.current = db;
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: _u1);
      await repo.watchAll().first;
      await repo.add(_txn('b', 2));
      // Then it opens again: the edit is there, not the older rows only.
      db = LocalDbRecordLists(factory);
      RecordLists.current = db;
      expect(await _ids(_u1), <String>['a', 'b']);
      expect((await _rows(factory, 'sb_txns_$_u1')).keys,
          unorderedEquals(<String>['a', 'b']));
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getStringList(LocalDbRecordLists.redoKey), isEmpty);
    });

    test('no database at all: the app works as before', () async {
      db = LocalDbRecordLists(_BrokenFactory());
      RecordLists.current = db;
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1)]),
      });
      expect(await _ids(_u1), <String>['a']);
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: _u1);
      await repo.add(_txn('b', 2));
      expect(SaveHealth.failing.value, isFalse);
      expect(await _pref('sb_txns_$_u1'), contains('"b"'));
    });
  });

  group('saving', () {
    test('a change writes that record only; the old copy follows', () async {
      // Records as the app writes them (a first save would otherwise
      // rewrite each one once, in its own form).
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[
          _txn('a', 1).toJson(),
          _txn('b', 2).toJson(),
        ]),
      });
      await _ids(_u1);
      await db.close();
      // Mark row «a» in the database: if a save rewrote it, the mark goes.
      final idb.Database raw = await factory.open(LocalDbRecordLists.dbName);
      final idb.Transaction t =
          raw.transaction('records', idb.idbModeReadWrite);
      final idb.ObjectStore s = t.objectStore('records');
      final Map<dynamic, dynamic> row =
          (await s.getObject('sb_txns_$_u1\na'))! as Map<dynamic, dynamic>;
      await s.put(<String, Object?>{...row.cast<String, Object?>(), 'mark': 1},
          'sb_txns_$_u1\na');
      await t.completed;
      raw.close();

      db = LocalDbRecordLists(factory);
      RecordLists.current = db;
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: _u1);
      await repo.watchAll().first;
      await repo.add(_txn('c', 3));
      await repo.delete('b');
      await db.close();
      final idb.Database check = await factory.open(LocalDbRecordLists.dbName);
      final idb.Transaction r =
          check.transaction('records', idb.idbModeReadOnly);
      final Map<dynamic, dynamic> a = (await r
          .objectStore('records')
          .getObject('sb_txns_$_u1\na'))! as Map<dynamic, dynamic>;
      await r.completed;
      check.close();
      expect(a['mark'], 1); // untouched
      expect((await _rows(factory, 'sb_txns_$_u1')).keys,
          unorderedEquals(<String>['a', 'c']));
      final List<dynamic> mirror =
          jsonDecode((await _pref('sb_txns_$_u1'))!) as List<dynamic>;
      expect(mirror.map((dynamic e) => e['id']),
          unorderedEquals(<String>['a', 'c']));
    });

    test('lists keep their order (wallets, trips... in the order made)',
        () async {
      final LocalListStore<String> store = LocalListStore<String>(
        key: 'sb_wallets_$_u1',
        fromJson: (Map<String, dynamic> j) => j['id'] as String,
        toJson: (String id) => <String, dynamic>{'id': id},
        idOf: (String id) => id,
      );
      seed(<String, Object>{});
      for (final String id in <String>['z', 'm', 'a']) {
        await store.upsert(id);
      }
      final LocalListStore<String> again = LocalListStore<String>(
        key: 'sb_wallets_$_u1',
        fromJson: (Map<String, dynamic> j) => j['id'] as String,
        toJson: (String id) => <String, dynamic>{'id': id},
        idOf: (String id) => id,
      );
      db = LocalDbRecordLists(factory);
      RecordLists.current = db;
      expect(await again.all(), <String>['z', 'm', 'a']);
    });

    test('a save the database refuses is shown and kept for a retry', () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1)])
      });
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: _u1);
      await repo.watchAll().first;
      await db.close(); // as when a newer version in another tab upgrades
      await repo.add(_txn('b', 2));
      expect(SaveHealth.failing.value, isTrue);
      expect(repo.current.length, 2); // still on screen, in the backup
    });

    test('an unreadable record is set aside, the rest loads', () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[
          _t('a', 1),
          <String, dynamic>{'id': 'broken', 'amountMinor': 'lots'},
        ]),
      });
      expect(await _ids(_u1), <String>['a']);
      final idb.Database raw = await factory.open(LocalDbRecordLists.dbName);
      final idb.Transaction t =
          raw.transaction('quarantine', idb.idbModeReadOnly);
      final List<Object> aside = await t.objectStore('quarantine').getAll();
      await t.completed;
      raw.close();
      expect(aside.single, isA<Map<dynamic, dynamic>>());
      expect((aside.single as Map<dynamic, dynamic>)['id'], 'broken');
    });
  });

  group('loading', () {
    test('a second reader while the list loads waits for it (never empty)',
        () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1), _t('b', 2)]),
      });
      final LocalListStore<String> wallets = LocalListStore<String>(
        key: 'sb_txns_$_u1',
        fromJson: (Map<String, dynamic> j) => j['id'] as String,
        toJson: (String id) => <String, dynamic>{'id': id},
        idOf: (String id) => id,
      );
      // Both start before the first has finished reading.
      final List<List<String>> got = await Future.wait(
          <Future<List<String>>>[wallets.all(), wallets.all()]);
      expect(got[0], hasLength(2));
      expect(got[1], hasLength(2));
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: _u1);
      final Future<void> first = repo.watchAll().first;
      await repo.add(_txn('c', 3)); // waits for the load, then adds
      await first;
      expect(repo.current.map((Transaction t) => t.id),
          containsAll(<String>['a', 'b', 'c']));
    });
  });

  group('versions', () {
    test('an upgrade keeps every record', () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1), _t('b', 2)]),
      });
      await _ids(_u1);
      await db.close();
      db = LocalDbRecordLists(factory, steps: <LocalDbStep>[
        ...LocalDbRecordLists.schema,
        (idb.Database d, idb.Transaction _) => d.createObjectStore('settings'),
      ]);
      RecordLists.current = db;
      expect(await _ids(_u1), <String>['a', 'b']);
      final idb.Database raw = await factory.open(LocalDbRecordLists.dbName);
      expect(raw.version, 2);
      expect(raw.objectStoreNames, contains('settings'));
      raw.close();
    });

    test('a newer version opens while an older one is open', () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1)])
      });
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: _u1);
      await repo.watchAll().first;
      final LocalDbRecordLists newer =
          LocalDbRecordLists(factory, steps: <LocalDbStep>[
        ...LocalDbRecordLists.schema,
        (idb.Database d, idb.Transaction _) => d.createObjectStore('settings'),
      ]);
      final List<Transaction> got = await newer.load(
          'sb_txns_$_u1', (Map<String, dynamic> j) => Transaction.fromJson(j));
      expect(got.single.id, 'a');
      // (A browser also asks the older connection to close: checked in
      // Chromium, the in-memory stand-in used here doesn't.)
      await newer.close();
    });
  });

  group('turning it off', () {
    test('what the old copy missed is copied back, then the database emptied',
        () async {
      db = LocalDbRecordLists(factory, mirror: false); // the old copy lags
      RecordLists.current = db;
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1)])
      });
      final FakeTransactionRepository repo =
          FakeTransactionRepository(userId: _u1);
      await repo.watchAll().first;
      await repo.add(_txn('b', 2));
      expect(await _pref('sb_txns_$_u1'), isNot(contains('"b"')));
      await db.close();

      await chooseRecordLists(enabled: false, factory: factory);
      expect(RecordLists.current, isA<PrefsRecordLists>());
      expect(await _ids(_u1), <String>['a', 'b']);
      expect(await _rows(factory, 'sb_txns_$_u1'), isEmpty);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getBool(LocalDbRecordLists.usedKey), isNull);

      // On again: moved in afresh, from the copy now complete.
      db = LocalDbRecordLists(factory);
      RecordLists.current = db;
      expect(await _ids(_u1), <String>['a', 'b']);
      expect(db.usesDatabaseFor('sb_txns_$_u1'), isTrue);
    });

    test('never used: nothing to do', () async {
      seed(<String, Object>{});
      await chooseRecordLists(enabled: false, factory: factory);
      expect(RecordLists.current, isA<PrefsRecordLists>());
    });
  });

  group('accounts', () {
    test('each account sees its own; removing one removes only its rows',
        () async {
      seed(<String, Object>{
        'sb_txns_$_u1': jsonEncode(<Object>[_t('a', 1)]),
        'sb_txns_$_u2': jsonEncode(<Object>[_t('x', 9)]),
      });
      expect(await _ids(_u1), <String>['a']);
      expect(await _ids(_u2), <String>['x']);
      final SharedPreferences p = await SharedPreferences.getInstance();
      await AccountDeletion.wipeLocal(p, _u1);
      expect(await _rows(factory, 'sb_txns_$_u1'), isEmpty);
      expect(await _rows(factory, 'sb_txns_$_u2'), hasLength(1));
      expect(await _ids(_u1), isEmpty);
      expect(await _ids(_u2), <String>['x']);
    });

    test('a list moves to the account that takes it over', () async {
      seed(<String, Object>{
        'sb_txns_dev-7': jsonEncode(<Object>[_t('a', 1)]),
      });
      expect(await _ids('dev-7'), <String>['a']);
      await db.move('sb_txns_dev-7', 'sb_txns_$_u1');
      expect(await _rows(factory, 'sb_txns_dev-7'), isEmpty);
      expect((await _rows(factory, 'sb_txns_$_u1')).keys, <String>['a']);
    });
  });
}

/// A browser without IndexedDB (or one that refuses it).
class _BrokenFactory implements idb.IdbFactory {
  @override
  Future<idb.Database> open(String dbName,
          {int? version,
          idb.OnUpgradeNeededFunction? onUpgradeNeeded,
          idb.OnBlockedFunction? onBlocked}) =>
      Future<idb.Database>.error(StateError('no IndexedDB'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
