import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multi-currency upgrade texts mention debts in every language', () {
    final files = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'app_\w+\.arb$').hasMatch(f.path))
        .toList();
    expect(files.length, 23);
    for (final f in files) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final k in ['featMultiCurrency', 'planFeatMultiCurrency']) {
        expect((m[k] as String).trim(), isNotEmpty, reason: '${f.path} $k');
      }
    }
    Map<String, dynamic> load(String l) =>
        jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(load('en')['featMultiCurrency'], contains('debts'));
    expect(load('en')['planFeatMultiCurrency'], contains('debts'));
    expect(load('ar')['featMultiCurrency'], contains('الديون'));
    expect(load('ar')['planFeatMultiCurrency'], contains('وديون'));
  });
}
