import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/data/lock_store.dart';
import 'package:smartbudget/features/app_lock/domain/lock_config.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  tearDown(AppClock.reset);

  group('PIN hashing', () {
    test('only 4–6 digits are valid', () {
      expect(PinHasher.isValid('1234'), isTrue);
      expect(PinHasher.isValid('123456'), isTrue);
      expect(PinHasher.isValid('123'), isFalse);
      expect(PinHasher.isValid('1234567'), isFalse);
      expect(PinHasher.isValid('12a4'), isFalse);
    });

    test('the PIN is never stored, and only the right PIN matches', () {
      final LockConfig c = const LockConfig().withPin('2468', random: Random(1));
      expect(c.enabled, isTrue);
      expect(c.pinLength, 4);
      expect(c.toJson().toString(), isNot(contains('2468')));
      expect(c.matches('2468'), isTrue);
      expect(c.matches('2469'), isFalse);
      expect(c.matches('24680'), isFalse);
    });

    test('the same PIN hashes differently with a new salt', () {
      final LockConfig a = const LockConfig().withPin('1111');
      final LockConfig b = const LockConfig().withPin('1111');
      expect(a.pinHash, isNot(b.pinHash));
    });

    test('survives a save/load round trip', () async {
      await LockStore.save(
          const LockConfig().withPin('9876').copyWith(autoLockMinutes: 5));
      final LockConfig back = await LockStore.load();
      expect(back.matches('9876'), isTrue);
      expect(back.autoLockMinutes, 5);
      await LockStore.save(const LockConfig());
      expect((await LockStore.load()).enabled, isFalse);
    });
  });

  test('lockout grows after repeated wrong PINs and is capped', () {
    expect(lockoutAfter(4), Duration.zero);
    expect(lockoutAfter(5), const Duration(seconds: 30));
    expect(lockoutAfter(6), const Duration(seconds: 60));
    expect(lockoutAfter(50), const Duration(minutes: 15));
  });

  group('AppLockController', () {
    ProviderContainer containerWith(LockConfig c) {
      final ProviderContainer pc = ProviderContainer(overrides: <Override>[
        initialLockConfigProvider.overrideWithValue(c),
      ]);
      addTearDown(pc.dispose);
      return pc;
    }

    test('starts locked when a PIN is set, unlocked otherwise', () {
      expect(containerWith(const LockConfig()).read(appLockProvider).locked,
          isFalse);
      expect(
          containerWith(const LockConfig().withPin('1234'))
              .read(appLockProvider)
              .locked,
          isTrue);
    });

    test('unlocks with the right PIN; 5 wrong PINs impose a wait', () {
      final ProviderContainer pc = containerWith(const LockConfig().withPin('1234'));
      final AppLockController ctrl = pc.read(appLockProvider.notifier);
      for (int i = 0; i < 5; i++) {
        expect(ctrl.unlockWithPin('0000'), PinResult.wrong);
      }
      expect(ctrl.waitRemaining, greaterThan(Duration.zero));
      expect(ctrl.unlockWithPin('1234'), PinResult.waiting);
      expect(pc.read(appLockProvider).locked, isTrue);

      AppClock.applyOffset(const Duration(minutes: 1));
      expect(ctrl.unlockWithPin('1234'), PinResult.ok);
      expect(pc.read(appLockProvider).locked, isFalse);
      expect(pc.read(appLockProvider).failures, 0);
    });

    test('re-locks only after the chosen time away', () {
      final ProviderContainer pc = containerWith(
          const LockConfig().withPin('1234').copyWith(autoLockMinutes: 5));
      final AppLockController ctrl = pc.read(appLockProvider.notifier);
      ctrl.unlockWithPin('1234');

      ctrl.onHidden();
      AppClock.applyOffset(const Duration(minutes: 2));
      ctrl.onShown();
      expect(pc.read(appLockProvider).locked, isFalse);

      ctrl.onHidden();
      AppClock.applyOffset(const Duration(minutes: 8));
      ctrl.onShown();
      expect(pc.read(appLockProvider).locked, isTrue);
    });

    test('setting and removing a PIN persists and never leaves it locked',
        () async {
      final ProviderContainer pc = containerWith(const LockConfig());
      final AppLockController ctrl = pc.read(appLockProvider.notifier);
      await ctrl.setPin('4321');
      expect(pc.read(appLockProvider).config.enabled, isTrue);
      expect(pc.read(appLockProvider).locked, isFalse);
      expect((await LockStore.load()).matches('4321'), isTrue);
      await ctrl.disable();
      expect((await LockStore.load()).enabled, isFalse);
    });

    test('recovery code resets the PIN, keeps data and retires the code',
        () async {
      final ProviderContainer pc = containerWith(const LockConfig());
      final AppLockController ctrl = pc.read(appLockProvider.notifier);
      final String code = await ctrl.enable('1234');
      expect(pc.read(appLockProvider).config.hasRecovery, isTrue);
      ctrl.lock();

      expect(ctrl.checkRecovery('AAAA-AAAA-AAAA'), PinResult.wrong);
      // Lower-case, spaces: still accepted.
      final String typed = code.toLowerCase().replaceAll('-', ' ');
      expect(ctrl.checkRecovery(typed), PinResult.ok);
      expect(pc.read(appLockProvider).locked, isTrue);

      final String? fresh = await ctrl.resetWithRecovery(typed, '9876');
      expect(fresh, isNotNull);
      expect(fresh, isNot(code));
      // Still locked until the new code has been shown.
      expect(pc.read(appLockProvider).locked, isTrue);
      ctrl.finishRecovery();
      expect(pc.read(appLockProvider).locked, isFalse);

      final LockConfig saved = await LockStore.load();
      expect(saved.matches('9876'), isTrue);
      expect(saved.matchesRecovery(code), isFalse);
      expect(saved.matchesRecovery(fresh!), isTrue);
    });

    test('wrong recovery codes share the PIN lock-out', () {
      final ProviderContainer pc = containerWith(
          const LockConfig().withPin('1234').withRecovery('K7QM-2XPA-9RTD'));
      final AppLockController ctrl = pc.read(appLockProvider.notifier);
      for (int i = 0; i < 5; i++) {
        expect(ctrl.checkRecovery('ZZZZ-ZZZZ-ZZZZ'), PinResult.wrong);
      }
      expect(ctrl.checkRecovery('K7QM-2XPA-9RTD'), PinResult.waiting);
    });

    test('changing the PIN keeps the recovery code', () async {
      final ProviderContainer pc = containerWith(const LockConfig());
      final AppLockController ctrl = pc.read(appLockProvider.notifier);
      final String code = await ctrl.enable('1234');
      await ctrl.setPin('5555');
      expect(pc.read(appLockProvider).config.matchesRecovery(code), isTrue);
      final String next = await ctrl.newRecoveryCode();
      expect(pc.read(appLockProvider).config.matchesRecovery(code), isFalse);
      expect(pc.read(appLockProvider).config.matchesRecovery(next), isTrue);
    });
  });

  group('RecoveryCode', () {
    test('12 unambiguous characters in groups of 4', () {
      final String code = RecoveryCode.generate(Random(7));
      expect(code, matches(RegExp(r'^[2-9A-HJ-NP-Z]{4}(-[2-9A-HJ-NP-Z]{4}){2}$')));
      expect(RecoveryCode.isWellFormed(RecoveryCode.normalize(code)), isTrue);
      expect(RecoveryCode.isWellFormed('K7QM2XPA9RT0'), isFalse);
      expect(RecoveryCode.isWellFormed('K7QM2XPA'), isFalse);
    });
  });
}
