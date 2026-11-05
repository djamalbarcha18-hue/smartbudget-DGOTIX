import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/config/app_config.dart';

/// The product name is a technical brand, not a word: it is written
/// "SmartBudget", in Latin letters, in every language: never translated,
/// transliterated ("سمارت بدجت"), split ("Smart Budget") or shouted
/// ("SMARTBUDGET"). The generic adjective "smart" in feature names (smart
/// alerts, smart salary split) is a different thing and stays translated.
void main() {
  // The name in any spelling other than the one true one.
  final RegExp anySpelling =
      RegExp(r'smart[\s\-]?budget', caseSensitive: false);

  // The name rendered in another script or translated.
  final RegExp translated = RegExp(
    'سمارت|اسمارت|स्मार्ट\\s?बजट|スマート\\s?バジェット|스마트\\s?버짓|'
    'Смарт[\\s\\-]?бюджет|智能预算|智慧預算|Akıllı Bütçe|'
    'Presupuesto Inteligente|Budget Intelligent',
    caseSensitive: false,
  );

  test('the configured name is SmartBudget', () {
    expect(AppConfig.appName, 'SmartBudget');
  });

  final List<File> files = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((File f) => RegExp(r'app_\w+\.arb$').hasMatch(f.path))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  test('all 23 language files are checked', () {
    expect(files.length, 23);
  });

  for (final File f in files) {
    final String lang = f.path.split('_').last.replaceAll('.arb', '');
    test('$lang: the app name is only ever written SmartBudget', () {
      final Map<String, dynamic> arb =
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      expect(arb['appTitle'], 'SmartBudget');
      for (final MapEntry<String, dynamic> e in arb.entries) {
        final Object? v = e.value;
        if (v is! String || e.key.startsWith('@')) continue;
        for (final RegExpMatch m in anySpelling.allMatches(v)) {
          expect(m.group(0), 'SmartBudget',
              reason: '${e.key} spells the name "${m.group(0)}"');
        }
        expect(translated.hasMatch(v), isFalse,
            reason: '${e.key} translates or transliterates the name');
      }
    });
  }
}
