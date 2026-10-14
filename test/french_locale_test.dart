import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
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
  test('French is a supported locale, in the app and the language list', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(<String>['ar', 'en', 'fr']));
    expect(SupportedLocales.all.map((l) => l.languageCode),
        containsAll(<String>['ar', 'en', 'fr']));
  });

  test('every string exists in French, with the same placeholders', () {
    final Map<String, dynamic> en = _arb('en'), fr = _arb('fr');
    final Iterable<String> keys =
        en.keys.where((String k) => !k.startsWith('@'));
    for (final String k in keys) {
      expect(fr.containsKey(k), isTrue, reason: 'missing in French: $k');
      expect(_placeholders(fr[k] as String), _placeholders(en[k] as String),
          reason: 'placeholders differ: $k');
    }
    expect(fr.keys.where((String k) => !k.startsWith('@')).length, keys.length);
  });

  test('categories and payment methods have French labels', () {
    for (final TransactionType t in TransactionType.values) {
      for (final String c in Catalog.categoriesFor(t)) {
        final String label = Catalog.label(c, lang: AppLang.fr);
        expect(_arabicLetters.hasMatch(label), isFalse, reason: c);
      }
    }
    for (final String m in Catalog.paymentMethods) {
      expect(
          _arabicLetters.hasMatch(Catalog.label(m, lang: AppLang.fr)), isFalse,
          reason: m);
    }
    // The stored value stays the Arabic key; only the display changes.
    expect(Catalog.label('المطاعم', lang: AppLang.ar), 'المطاعم');
    expect(Catalog.label('المطاعم', lang: AppLang.fr), 'Restaurants');
  });

  test('French month names, Gregorian and Hijri', () {
    expect(MonthNames.full(lang: AppLang.fr).first, 'janvier');
    expect(MonthNames.short(lang: AppLang.fr), hasLength(12));
    expect(const HijriDate(1447, 9, 1).format(lang: AppLang.fr),
        '1 Ramadan 1447 H');
  });

  test('the privacy policy and terms exist in French, section for section', () {
    for (final LegalDoc doc in LegalDoc.values) {
      final List<LegalSection> en =
          LegalContent.sections(doc, lang: AppLang.en);
      final List<LegalSection> fr =
          LegalContent.sections(doc, lang: AppLang.fr);
      expect(fr.length, en.length);
      expect(fr.first.heading, isNot(en.first.heading));
    }
  });

  test('an unknown language code reads as English', () {
    expect(AppLang.fromCode('fr'), AppLang.fr);
    expect(AppLang.fromCode('de'), AppLang.en);
    expect(AppLang.fr.pick('ع', 'en'), 'en');
    expect(AppLang.fr.pick('ع', 'en', fr: 'fr'), 'fr');
  });
}
