import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/features/assistant/application/ask_ai_controller.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/zakat/application/zakat_controller.dart';

/// Lets pending reads from the device finish.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('AccountKeys.open', () {
    test('gives a device-wide value to the first signed-in account', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{'sb_x': 'old'});
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(await AccountKeys.open(p, 'sb_x', 'a'), 'sb_x_a');
      expect(p.getString('sb_x_a'), 'old');
      expect(p.containsKey('sb_x'), isFalse);
      // The next account starts empty.
      expect(await AccountKeys.open(p, 'sb_x', 'b'), 'sb_x_b');
      expect(p.containsKey('sb_x_b'), isFalse);
    });

    test('never overwrites what the account already has', () async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'sb_x': 'old', 'sb_x_a': 'mine'});
      final SharedPreferences p = await SharedPreferences.getInstance();
      await AccountKeys.open(p, 'sb_x', 'a');
      expect(p.getString('sb_x_a'), 'mine');
      expect(p.containsKey('sb_x'), isFalse);
    });

    test('signed out: nothing is taken over', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{'sb_x': 1.5});
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(await AccountKeys.open(p, 'sb_x', null), 'sb_x_guest');
      expect(p.getDouble('sb_x'), 1.5);
    });
  });

  group('per-account data', () {
    late StateController<String?> signedIn;
    late ProviderContainer container;

    setUp(() {
      final StateProvider<String?> account = StateProvider<String?>((_) => 'a');
      container = ProviderContainer(overrides: <Override>[
        currentAccountIdProvider
            .overrideWith((Ref ref) => ref.watch(account)),
      ]);
      signedIn = container.read(account.notifier);
    });
    tearDown(() => container.dispose());

    test('an AI conversation is seen only by the account that had it',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sb_ai_chat': '[{"u":true,"t":"How much did I spend?"}]',
      });
      container.listen(chatMessagesProvider, (_, __) {});
      await settle();
      expect(container.read(chatMessagesProvider).single.text,
          'How much did I spend?');

      signedIn.state = 'b';
      await settle();
      expect(container.read(chatMessagesProvider), isEmpty);
      container.read(chatMessagesProvider.notifier).add(
          const ChatMessage(fromUser: true, text: 'Hello'));
      await settle();

      signedIn.state = 'a';
      await settle();
      expect(container.read(chatMessagesProvider).single.text,
          'How much did I spend?');
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.containsKey('sb_ai_chat'), isFalse);
    });

    test('zakat amounts follow the account', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'sb_zakat_inputs': '{"gold":70,"silver":1,"cash":5000}',
      });
      container.listen(zakatInputsProvider, (_, __) {});
      await settle();
      expect(container.read(zakatInputsProvider).cash, 5000);

      signedIn.state = 'b';
      await settle();
      expect(container.read(zakatInputsProvider).cash, 0);
    });
  });
}
