import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/network/connectivity.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/application/backup_controller.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/sync/application/sync_controller.dart';
import 'package:smartbudget/features/sync/data/sync_remote.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// The account's cloud copy, with the same version check as user_backups.
class FakeRemote implements SyncRemote {
  Map<String, dynamic>? doc;
  int? version;
  int pulls = 0, pushes = 0;

  /// Runs (once) between a device's download and its upload: another device
  /// uploading first.
  void Function()? before;

  @override
  Future<RemoteCopy> pull() async {
    pulls++;
    return RemoteCopy(doc: doc, version: version);
  }

  @override
  Future<bool> push(Map<String, dynamic> d, RemoteCopy base) async {
    pushes++;
    final void Function()? other = before;
    before = null;
    other?.call();
    if (base.version != version) return false;
    doc = d;
    version = (version ?? 0) + 1;
    return true;
  }
}

/// One device: its own stored data (SharedPreferences), the shared cloud.
class Device {
  Device(this.remote);
  final FakeRemote remote;
  Map<String, Object> prefs = <String, Object>{};
  ProviderContainer? _c;

  Future<ProviderContainer> open({bool online = true}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      syncAvailableProvider.overrideWithValue(true),
      syncRemoteProvider.overrideWithValue(remote),
      currentAccountIdProvider.overrideWithValue('acc-1'),
      onlineProvider.overrideWith((_) => Stream<bool>.value(online)),
    ]);
    c.listen(syncControllerProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _c = c;
  }

  /// Saves what this device stored and closes it.
  Future<void> close() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    prefs = <String, Object>{for (final String k in p.getKeys()) k: p.get(k)!};
    _c?.dispose();
  }
}

Future<void> sync(ProviderContainer c) =>
    c.read(syncControllerProvider.notifier).syncNow();

Future<void> seed(ProviderContainer c) => c.read(backupServiceProvider).importData(
      BackupData.fromJson(<String, dynamic>{
        'baseCurrency': 'DZD',
        'transactions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 't1', 'date': '2026-10-05T10:00:00.000', 'type': 'expense',
            'category': 'Food', 'amountMinor': 250000, 'currency': 'DZD',
          },
        ],
        'wallets': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'w1', 'name': 'Cash', 'type': 'cash', 'openingMinor': 0,
            'currency': 'DZD', 'createdAt': '2026-10-01T00:00:00.000',
          },
        ],
      }),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('two devices: additions, edits and deletions reach each other', () async {
    final FakeRemote remote = FakeRemote();
    final Device a = Device(remote), b = Device(remote);

    ProviderContainer c = await a.open();
    await seed(c);
    await sync(c);
    expect(c.read(syncControllerProvider).phase, SyncPhase.idle);
    expect(remote.version, 1);
    await a.close();

    // A new device signs in: it gets everything.
    c = await b.open();
    await sync(c);
    expect((await c.read(transactionsProvider.future)).map((t) => t.id), <String>['t1']);
    expect((await c.read(walletStoreProvider).all()).single.name, 'Cash');

    // B renames the wallet and deletes the expense.
    final Wallet w = (await c.read(walletStoreProvider).all()).single;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await c.read(walletStoreProvider).upsert(Wallet.fromJson(<String, dynamic>{...w.toJson(), 'name': 'Wallet'}));
    await c.read(financeRepositoryProvider).delete('t1');
    await sync(c);
    await b.close();

    // A comes back: the rename and the deletion apply; nothing returns.
    c = await a.open();
    await sync(c);
    expect(await c.read(transactionsProvider.future), isEmpty);
    expect((await c.read(walletStoreProvider).all()).single.name, 'Wallet');
    await sync(c);
    expect(await c.read(transactionsProvider.future), isEmpty);
    await a.close();
  });

  test('offline: changes are noted and nothing is sent; sent once back online',
      () async {
    final FakeRemote remote = FakeRemote();
    final Device a = Device(remote);
    ProviderContainer c = await a.open(online: false);
    await seed(c);
    await sync(c);
    expect(c.read(syncControllerProvider).phase, SyncPhase.offline);
    expect(remote.pulls, 0);
    await a.close();

    c = await a.open();
    await sync(c);
    expect(c.read(syncControllerProvider).phase, SyncPhase.idle);
    expect(remote.doc, isNotNull);
    await a.close();
  });

  test('another device uploading at the same moment is merged, not overwritten',
      () async {
    final FakeRemote remote = FakeRemote();
    final Device a = Device(remote), b = Device(remote);
    ProviderContainer c = await a.open();
    await seed(c);
    await sync(c);
    await a.close();

    c = await b.open();
    await sync(c);
    await c.read(walletStoreProvider).upsert(Wallet.fromJson(<String, dynamic>{
      'id': 'w2', 'name': 'Bank', 'type': 'bank', 'openingMinor': 0,
      'currency': 'DZD', 'createdAt': '2026-10-02T00:00:00.000',
    }));
    // While B uploads, "another device" adds wallet w3 to the cloud.
    remote.before = () {
      final Map<String, dynamic> d = Map<String, dynamic>.from(remote.doc!);
      final Map<String, dynamic> cs = Map<String, dynamic>.from(d['c'] as Map);
      final Map<String, dynamic> ws = Map<String, dynamic>.from(cs['wallets'] as Map);
      ws['w3'] = <String, dynamic>{
        't': DateTime.now().millisecondsSinceEpoch,
        'd': <String, dynamic>{'id': 'w3', 'name': 'Gold', 'type': 'other', 'openingMinor': 0, 'currency': 'DZD', 'createdAt': '2026-10-03T00:00:00.000'},
      };
      cs['wallets'] = ws;
      d['c'] = cs;
      remote.doc = d;
      remote.version = remote.version! + 1;
    };
    await sync(c);
    final Set<String> ids = (await c.read(walletStoreProvider).all()).map((Wallet w) => w.id).toSet();
    expect(ids, containsAll(<String>['w1', 'w2', 'w3']));
    final Map<String, dynamic> cloudWallets = ((remote.doc!['c'] as Map)['wallets'] as Map).cast<String, dynamic>();
    expect(cloudWallets.keys, containsAll(<String>['w1', 'w2', 'w3']));
    await b.close();
  });

  test('sync off: nothing is sent', () async {
    final FakeRemote remote = FakeRemote();
    final Device a = Device(remote);
    final ProviderContainer c = await a.open();
    await c.read(syncEnabledProvider.notifier).set(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.read(syncControllerProvider).phase, SyncPhase.off);
    await sync(c);
    expect(remote.pulls, 0);
    await a.close();
  });
}
