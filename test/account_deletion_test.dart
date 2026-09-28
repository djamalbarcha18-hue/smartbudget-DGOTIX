import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/account/application/account_deletion.dart';

void main() {
  test('deleting the account leaves no app data on the device', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_txns_u1': '[]',
      'sb_ai_chat': '[]',
      'sb_app_lock': '{}',
      'sb_auth_uid': 'u1',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await AccountDeletion.wipeLocal(prefs);
    expect(prefs.getKeys(), isEmpty);
  });
}
