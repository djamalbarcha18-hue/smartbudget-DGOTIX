import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/stats/app_stats.dart';
import 'package:smartbudget/features/trips/application/trips_controller.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';

void main() {
  Trip trip(String id, {String name = 'Istanbul'}) => Trip(
        id: id,
        name: name,
        destination: 'Istanbul',
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 5),
        createdAt: DateTime(2026, 10, 1),
      );

  late List<String> sent;
  ProviderContainer container() {
    sent = <String>[];
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      statSenderProvider.overrideWithValue((String e) async => sent.add(e)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a new trip adds one; editing it adds nothing', () async {
    final ProviderContainer c = container();
    final TripActions actions = c.read(tripActionsProvider);
    await actions.save(trip('t1'));
    await settle();
    expect(sent, <String>['trip_created']);

    await actions.save(trip('t1', name: 'Istanbul (edited)'));
    await actions.save(trip('t2'));
    await settle();
    expect(sent, <String>['trip_created', 'trip_created']);
  });

  test('turned off in Settings: nothing is sent', () async {
    final ProviderContainer c = container();
    await c.read(appStatsOnProvider.notifier).set(false);
    expect(c.read(appStatsOnProvider), isFalse);
    await c.read(tripActionsProvider).save(trip('t1'));
    await settle();
    expect(sent, isEmpty);

    await c.read(appStatsOnProvider.notifier).set(true);
    await c.read(tripActionsProvider).save(trip('t2'));
    await settle();
    expect(sent, <String>['trip_created']);
  });

  test('a failing send never reaches the user', () async {
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      statSenderProvider.overrideWithValue((_) async => throw Exception('x')),
    ]);
    addTearDown(c.dispose);
    await c.read(tripActionsProvider).save(trip('t1'));
    await settle();
    expect(await c.read(tripStoreProvider).all(), hasLength(1));
  });

  test('hidden: off in every build until turned on (ANON_STATS)', () {
    expect(AppEnv.anonStats, isFalse);
  });

  test('the app and the database know the same event names', () {
    final String sql = File('supabase/app_stats.sql').readAsStringSync();
    for (final StatEvent e in StatEvent.values) {
      expect(sql, contains("'${e.id}'"));
    }
  });
}
