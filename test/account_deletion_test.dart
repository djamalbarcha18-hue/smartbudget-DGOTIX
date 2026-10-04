import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/account/application/account_deletion.dart';

const String a = '11111111-2222-3333-4444-555555555555';
const String b = '66666666-7777-8888-9999-000000000000';

void main() {
  test('the only account on the device: no app data is left', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_txns_$a': '[]',
      'sb_ai_chat': '[]',
      'sb_app_lock': '{}',
      'sb_locale': 'ar',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await AccountDeletion.wipeLocal(prefs, a);
    expect(prefs.getKeys(), isEmpty);
  });

  test("another account's data and the device settings stay", () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_txns_$a': '[]',
      'sb_ai_chat_$a': '[]',
      'sb_zakat_inputs': '{}',
      'sb_entitlement': '{}',
      'sb_txns_$b': '[1]',
      'sb_ai_chat_$b': '[2]',
      'sb_txns_dev-12345': '[3]',
      'sb_app_lock': '{}',
      'sb_locale': 'ar',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await AccountDeletion.wipeLocal(prefs, a);
    expect(prefs.getKeys(), <String>{
      'sb_txns_$b',
      'sb_ai_chat_$b',
      'sb_txns_dev-12345',
      'sb_app_lock',
      'sb_locale',
    });
  });
}
