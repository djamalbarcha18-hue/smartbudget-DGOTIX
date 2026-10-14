import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/zakat/domain/hijri_date.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)[,}]').allMatches(s).map((Match m) => m[1]!).toSet();

final RegExp _arabicLetters = RegExp('[؀-ۿ]');

void main() {
  test('Spanish is a supported locale', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('es'));
    expect(SupportedLocales.all.map((l) => l.languageCode), contains('es'));
    expect(AppLang.fromCode('es'), AppLang.es);
  });

  test('every string exists in Spanish, with the same placeholders', () {
    final Map<String, dynamic> en = _arb('en'), es = _arb('es');
    final Iterable<String> keys =
        en.keys.where((String k) => !k.startsWith('@'));
    for (final String k in keys) {
      expect(es.containsKey(k), isTrue, reason: 'missing in Spanish: $k');
      expect(_placeholders(es[k] as String), _placeholders(en[k] as String),
          reason: 'placeholders differ: $k');
    }
  });

  test('categories, months and the Hijri calendar in Spanish', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.es)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('السكن', lang: AppLang.es), 'Vivienda');
    expect(MonthNames.full(lang: AppLang.es).first, 'enero');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.es),
        '1 Ramadán 1447 H');
  });

  test('the privacy policy and terms exist in Spanish', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.es).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
    }
  });

  test('Latin American pesos and the sol are currencies', () {
    for (final String code in <String>['ARS', 'COP', 'CLP', 'PEN', 'MXN']) {
      expect(Currencies.byCode(code).code, code);
    }
    expect(Currencies.byCode('CLP').decimals, 0);
  });

  group('quick entry in Spanish', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('everyday words, "ayer" and accents', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'café 2,5; taxi 12 ayer; sueldo 1500; farmacia 8',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(), <String>[
        'المطاعم',
        'النقل',
        'راتب أساسي',
        'الصحة',
      ]);
      expect(all[0].amount, 2.5);
      expect(all[1].date, DateTime(2026, 10, 13));
      expect(all[2].type, TransactionType.income);
    });

    test('"mil" is a thousand', () {
      final QuickEntry? rent =
          QuickEntryParser.parse('alquiler 5 mil', today: today);
      expect(rent!.amount, 5000);
      expect(rent.category, 'السكن');
    });
  });
}
