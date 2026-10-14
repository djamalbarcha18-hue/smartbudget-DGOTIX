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
  test('Indonesian is a supported locale', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('id'));
    expect(SupportedLocales.all.map((l) => l.languageCode), contains('id'));
    expect(AppLang.fromCode('id'), AppLang.id);
  });

  test('every string exists in Indonesian, with the same placeholders', () {
    final Map<String, dynamic> en = _arb('en'), id = _arb('id');
    final Iterable<String> keys =
        en.keys.where((String k) => !k.startsWith('@'));
    for (final String k in keys) {
      expect(id.containsKey(k), isTrue, reason: 'missing in Indonesian: $k');
      expect(_placeholders(id[k] as String), _placeholders(en[k] as String),
          reason: 'placeholders differ: $k');
    }
  });

  test('categories, months and the Hijri calendar in Indonesian', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        expect(_arabicLetters.hasMatch(Catalog.label(c, lang: AppLang.id)),
            isFalse,
            reason: c);
      }
    }
    expect(Catalog.label('النقل', lang: AppLang.id), 'Transportasi');
    expect(MonthNames.full(lang: AppLang.id)[7], 'Agustus');
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.id),
        '1 Ramadan 1447 H');
  });

  test('the privacy policy and terms exist in Indonesian', () {
    for (final LegalDoc doc in LegalDoc.values) {
      expect(LegalContent.sections(doc, lang: AppLang.id).length,
          LegalContent.sections(doc, lang: AppLang.en).length);
    }
  });

  test('the rupiah is a currency, without cents', () {
    final Currency idr = Currencies.byCode('IDR');
    expect(idr.code, 'IDR');
    expect(idr.decimals, 0);
  });

  group('quick entry in Indonesian', () {
    final DateTime today = DateTime(2026, 10, 14);

    test('"rb" is a thousand and "jt" a million', () {
      final QuickEntry? coffee =
          QuickEntryParser.parse('kopi 25rb', today: today);
      expect(coffee!.amount, 25000);
      expect(coffee.category, 'المطاعم');
      final QuickEntry? salary =
          QuickEntryParser.parse('gaji 8,5jt', today: today);
      expect(salary!.amount, 8500000);
      expect(salary.type, TransactionType.income);
      expect(salary.category, 'راتب أساسي');
    });

    test('grouped rupiah amounts and "kemarin"', () {
      final QuickEntry? ride =
          QuickEntryParser.parse('ojek 15.000 kemarin', today: today);
      expect(ride!.amount, 15000);
      expect(ride.category, 'النقل');
      expect(ride.date, DateTime(2026, 10, 13));
    });

    test('several entries at once', () {
      final List<QuickEntry> all = QuickEntryParser.parseAll(
          'pulsa 50rb; bensin 30rb; listrik 200rb',
          today: today);
      expect(all.map((QuickEntry e) => e.category).toList(),
          <String>['الاتصالات والإنترنت', 'الوقود', 'الفواتير']);
    });
  });
}
