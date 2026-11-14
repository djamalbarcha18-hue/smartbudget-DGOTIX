import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/features/billing/data/trial_service.dart';

/// The trial's limits are told to the user (plans page) and enforced by the
/// server: the two must say the same thing.
void main() {
  final String quota =
      File('supabase/functions/_shared/quota.ts').readAsStringSync();

  int serverLimit(String name) {
    final RegExpMatch? m =
        RegExp('$name: Allowance = \\{ limit: (\\d+)').firstMatch(quota);
    expect(m, isNotNull, reason: '$name not found in quota.ts');
    return int.parse(m!.group(1)!);
  }

  test('the app tells the limits the server enforces', () {
    expect(kProTrialAi, serverLimit('TRIAL_AI_QUOTA'));
    expect(kProTrialScans, serverLimit('TRIAL_OCR_QUOTA'));
  });
}
