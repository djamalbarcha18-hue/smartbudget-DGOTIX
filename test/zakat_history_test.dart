import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/zakat/application/zakat_backup.dart';
import 'package:smartbudget/features/zakat/application/zakat_engine_providers.dart';
import 'package:smartbudget/features/zakat/application/zakat_history_controller.dart';
import 'package:smartbudget/features/zakat/domain/engine/profiles/algeria_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_engine.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_market.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_record.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_settings.dart';
import 'package:smartbudget/features/zakat/domain/zakat_assembler.dart';
import 'package:smartbudget/features/zakat/domain/zakat_calculator.dart';

int dzd(int whole) => whole * 100;

final DateTime today = DateTime(2026, 11, 15);
final DateTime start = DateTime(2025, 11, 1);

ZakatAssembly assemble(ZakatSettings s, {int wallet = 3000000}) =>
    ZakatAssembler.build(
      profile: algeriaZakatProfile,
      rules: ZakatMarkets.rulesFor(algeriaZakatProfile, s),
      settings: s,
      sources: ZakatSources(wallets: <Wallet>[
        Wallet.general('DZD', opening: Money(dzd(wallet), 'DZD')),
      ]),
      zakatDate: today,
    );

ZakatRecord record(String id,
    {ZakatSettings? settings, int wallet = 3000000}) {
  final ZakatAssembly a =
      assemble(settings ?? ZakatSettings(hawlStart: start), wallet: wallet);
  return ZakatRecord.fromOutcome(ZakatEngine.compute(a.zakatCase), a.zakatCase,
      id: id, savedAt: DateTime(2026, 11, 15, 10))!;
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('a confirmed record', () {
    test('keeps the amount, the rules version, the nisab and every line', () {
      final ZakatRecord r = record('zk-1');
      expect(r.status, 'final_');
      expect(r.country, 'DZ');
      expect(r.currency, 'DZD');
      expect(r.rulesVersion, 'dz-2026.11-maliki');
      expect(r.rules['school'], 'maliki');
      expect(r.nisab['basis'], 'official');
      expect(r.nisab['amountMinor'], dzd(2295000));
      expect(r.nisab['hijriYear'], 1447);
      expect(r.baseMinor, dzd(3000000));
      expect(r.dueMinor, dzd(75000));
      expect(r.obligatoryNow, isTrue);
      expect(r.hawlStart, start);
      expect(r.lines.single.key, 'wallet:general');
      expect(r.lines.single.note, 'counted');
    });

    test('reads back exactly as written', () {
      final ZakatRecord r = record('zk-1');
      final Object? json = jsonDecode(jsonEncode(r.toJson()));
      final ZakatRecord back = ZakatRecord.fromJson(json)!;
      expect(back.toJson(), r.toJson());
    });

    test('an incomplete result cannot be confirmed', () {
      final ZakatAssembly a = ZakatAssembler.build(
        profile: algeriaZakatProfile,
        rules: algeriaZakatProfile.defaultRules,
        settings: ZakatSettings(hawlStart: start),
        sources: ZakatSources(wallets: <Wallet>[
          Wallet.general('DZD', opening: Money(dzd(3000000), 'DZD')),
          Wallet(
              id: 'gbp',
              name: 'gbp',
              type: WalletType.bank,
              opening: Money(10000, 'GBP'),
              createdAt: DateTime(2025)),
        ]),
        zakatDate: today,
      );
      final ZakatOutcome o = ZakatEngine.compute(a.zakatCase);
      expect(o.status, ZakatStatus.incomplete);
      expect(
          ZakatRecord.fromOutcome(o, a.zakatCase, id: 'x', savedAt: today),
          isNull);
    });

    test('later changes to the rules or the data leave it as it was', () {
      final ZakatRecord r = record('zk-1');
      final String saved = jsonEncode(r.toJson());
      final List<Object?> history = ZakatHistory.append(<Object?>[], r);

      // Another school and more money afterwards: a new result…
      final ZakatRecord later = record('zk-2',
          settings: ZakatSettings(hawlStart: start, school: ZakatSchool.hanafi),
          wallet: 5000000);
      expect(later.dueMinor, isNot(r.dueMinor));
      expect(later.rulesVersion, isNot(r.rulesVersion));

      // …while the saved one is unchanged.
      expect(jsonEncode(history.single), saved);
      expect(ZakatHistory.read(history).single.dueMinor, dzd(75000));
    });
  });

  group('history', () {
    test('only grows: a known id is never replaced', () {
      final ZakatRecord r = record('zk-1');
      final List<Object?> h = ZakatHistory.append(<Object?>[], r);
      final ZakatRecord other = record('zk-1', wallet: 9000000);
      expect(ZakatHistory.append(h, other), same(h));
      expect(ZakatHistory.merge(h, <Object?>[other.toJson()]).length, 1);
      expect(ZakatHistory.read(ZakatHistory.merge(h, <Object?>[other.toJson()]))
          .single
          .dueMinor, dzd(75000));
    });

    test('keeps entries it cannot read, and lists the rest newest first', () {
      final Map<String, dynamic> future = <String, dynamic>{
        'id': 'zk-future',
        'v': 9,
        'shape': 'unknown',
      };
      final ZakatRecord a = record('zk-a');
      final Map<String, dynamic> b = record('zk-b').toJson()
        ..['zakatDate'] = DateTime(2027, 11, 4).toIso8601String();
      List<Object?> h = <Object?>[future];
      h = ZakatHistory.append(h, a);
      h = ZakatHistory.merge(h, <Object?>[b, 'garbage', null]);
      expect(h.length, 3);
      expect(h.first, future);
      expect(ZakatHistory.read(h).map((ZakatRecord r) => r.id),
          <String>['zk-b', 'zk-a']);
    });

    test('is stored per account and survives unreadable storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sb_zakat_history_u2': '{not json',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await ZakatHistoryStore.writeRaw(
          prefs, 'u1', ZakatHistory.append(<Object?>[], record('zk-1')));
      expect(ZakatHistoryStore.readRaw(prefs, 'u1').length, 1);
      expect(ZakatHistoryStore.readRaw(prefs, 'u2'), isEmpty);
      expect(ZakatHistoryStore.readRaw(prefs, null), isEmpty);
    });
  });

  group('backup file', () {
    Future<SharedPreferences> device(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferences.getInstance();
    }

    test('carries the settings and history to a new device', () async {
      final ZakatSettings s =
          ZakatSettings(hawlStart: start, goalsHeldOutside: const <String>{'g1'});
      final String history =
          jsonEncode(ZakatHistory.append(<Object?>[], record('zk-1')));
      SharedPreferences prefs = await device(<String, Object>{
        'sb_zakat_settings_u1': jsonEncode(s.toJson()),
        'sb_zakat_history_u1': history,
      });
      final Map<String, dynamic> section =
          ZakatBackupIo.export(prefs, 'u1', 'DZD')!;

      // The file as written, then read on a new device.
      final Map<String, dynamic> file = jsonDecode(jsonEncode(<String, dynamic>{
        ...BackupData(
          exportedAt: today,
          baseCurrency: 'DZD',
          transactions: const [],
          budgets: const [],
          customIncome: const [],
          customExpense: const [],
        ).toJson(),
        ZakatBackupIo.section: section,
      })) as Map<String, dynamic>;
      expect(BackupCodec.decodeJson(jsonEncode(file)).baseCurrency, 'DZD');

      prefs = await device(<String, Object>{});
      expect(await ZakatBackupIo.import(prefs, 'u1', file), 1);
      expect(prefs.getString('sb_zakat_history_u1'), history);
      final ZakatSettings restored = ZakatSettingsStore.read(prefs, 'u1', 'DZD');
      expect(restored.hawlStart, start);
      expect(restored.goalsHeldOutside, <String>{'g1'});

      // Importing the same file again adds nothing.
      expect(await ZakatBackupIo.import(prefs, 'u1', file), 0);
    });

    test('never overwrites what the device already has', () async {
      final ZakatRecord mine = record('zk-1');
      final Map<String, dynamic> file = <String, dynamic>{
        'zakat': <String, dynamic>{
          'settings':
              ZakatSettings(hawlStart: DateTime(2024, 1, 1)).toJson(),
          'history': <Object?>[
            record('zk-1', wallet: 9000000).toJson(),
            record('zk-2').toJson(),
          ],
        },
      };
      final String legacy = jsonEncode(<String, dynamic>{'cash': 5});
      final SharedPreferences prefs = await device(<String, Object>{
        'sb_zakat_inputs_u1': legacy,
        'sb_zakat_history_u1':
            jsonEncode(ZakatHistory.append(<Object?>[], mine)),
      });
      expect(await ZakatBackupIo.import(prefs, 'u1', file), 1);
      expect(prefs.containsKey('sb_zakat_settings_u1'), isFalse);
      expect(prefs.getString('sb_zakat_inputs_u1'), legacy);
      final List<ZakatRecord> h =
          ZakatHistory.read(ZakatHistoryStore.readRaw(prefs, 'u1'));
      expect(h.map((ZakatRecord r) => r.id).toSet(), <String>{'zk-1', 'zk-2'});
      expect(h.firstWhere((ZakatRecord r) => r.id == 'zk-1').dueMinor,
          dzd(75000));
    });

    test('a file without a zakat part, or nothing to carry', () async {
      final SharedPreferences prefs = await device(<String, Object>{});
      expect(ZakatBackupIo.export(prefs, 'u1', 'DZD'), isNull);
      expect(await ZakatBackupIo.import(prefs, 'u1', <String, dynamic>{}), 0);
      expect(prefs.getKeys(), isEmpty);
    });

    test('cloud sync is not given any zakat data', () {
      final Map<String, dynamic> synced = BackupData(
        exportedAt: today,
        baseCurrency: 'DZD',
        transactions: const [],
        budgets: const [],
        customIncome: const [],
        customExpense: const [],
      ).toJson();
      expect(synced.keys.where((String k) => k.contains('zakat')), isEmpty);
    });
  });

  group('dashboard and assistant', () {
    ZakatResult legacy() => ZakatCalculator.compute(const ZakatInput(
          currency: 'USD',
          standard: ZakatStandard.gold,
          goldPricePerGram: 100,
          silverPricePerGram: 1,
          savingsMinor: 0,
          surplusMinor: 1000000,
          receivablesMinor: 0,
          liabilitiesMinor: 0,
        ));

    test('follow the Algerian engine where it applies', () {
      final ZakatAssembly a = assemble(ZakatSettings(hawlStart: start));
      final ZakatDue d =
          ZakatDue.from(ZakatEngine.compute(a.zakatCase), legacy);
      expect(d.fromEngine, isTrue);
      expect(d.obligatory, isTrue);
      expect(d.due, Money(dzd(75000), 'DZD'));
    });

    test('are not due before the hawl is complete', () {
      final ZakatAssembly a =
          assemble(ZakatSettings(hawlStart: DateTime(2026, 6, 1)));
      final ZakatDue d =
          ZakatDue.from(ZakatEngine.compute(a.zakatCase), legacy);
      expect(d.obligatory, isFalse);
    });

    test('keep the older calculator elsewhere (Saudi Arabia included)', () {
      expect(ZakatMarkets.resolve(ZakatSettings.empty, 'SAR'), isNull);
      final ZakatDue d = ZakatDue.from(null, legacy);
      expect(d.fromEngine, isFalse);
      expect(d.obligatory, legacy().obligatory);
      expect(d.due, legacy().due);
    });
  });
}
