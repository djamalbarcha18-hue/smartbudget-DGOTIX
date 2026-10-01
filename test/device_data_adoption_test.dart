import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/features/auth/data/device_data_adoption.dart';
import 'package:smartbudget/features/auth/data/fake_auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_user.dart';

void main() {
  const AuthUser real =
      AuthUser(id: '7f1c-real-uuid', email: 'Sara@Example.com');
  final String devId = FakeAuthRepository.idFor('sara@example.com ');

  test('moves the device-only data of the same e-mail to the real account',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_txns_$devId': '[1]',
      'sb_goals_$devId': '[2]',
      'sb_base_currency': 'DZD',
      'sb_txns_dev-999': '[other]',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await adoptDeviceData(prefs, real);

    expect(prefs.getString('sb_txns_7f1c-real-uuid'), '[1]');
    expect(prefs.getString('sb_goals_7f1c-real-uuid'), '[2]');
    expect(prefs.containsKey('sb_txns_$devId'), isFalse);
    expect(prefs.getString('sb_base_currency'), 'DZD');
    expect(prefs.getString('sb_txns_dev-999'), '[other]');
  });

  test('never overwrites data the account already has', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_txns_$devId': '[old]',
      'sb_txns_7f1c-real-uuid': '[current]',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await adoptDeviceData(prefs, real);

    expect(prefs.getString('sb_txns_7f1c-real-uuid'), '[current]');
  });

  test('tells whether the device has data of a device-only account', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_txns_$devId': '[1]',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(hasDeviceOnlyData(prefs, ' SARA@example.com'), isTrue);
    expect(hasDeviceOnlyData(prefs, 'other@example.com'), isFalse);
  });
}
