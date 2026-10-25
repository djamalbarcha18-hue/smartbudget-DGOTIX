import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/month_names.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/features/guide/domain/guide_content.dart';
import 'package:smartbudget/features/legal/domain/legal_content.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

// Every language the app offers must be complete, so adding one is caught
// here if a step is missed (docs/ADDING_A_LANGUAGE.md).

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)[,}]').allMatches(s).map((Match m) => m[1]!).toSet();

final RegExp _arabicLetters = RegExp('[؀-ۿ]');

void main() {
  test('one ARB file per language, and nothing else', () {
    final Set<String> files = Directory('lib/l10n')
        .listSync()
        .map((FileSystemEntity f) => f.uri.pathSegments.last)
        .where((String n) => n.endsWith('.arb'))
        .map((String n) => n.substring(4, n.length - 4))
        .toSet();
    expect(files, AppLang.values.map((AppLang l) => l.code).toSet());
    for (final AppLang l in AppLang.values) {
      expect(_arb(l.code)['@@locale'], l.code);
    }
  });

  test('the app, the menus and Settings offer exactly these languages', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
        AppLang.values.map((AppLang l) => l.code).toSet());
    expect(SupportedLocales.all.map((l) => l.languageCode).toList(),
        AppLang.offered.map((AppLang l) => l.code).toList());
    expect(AppLang.values.first, AppLang.ar, reason: 'Arabic-first');
    for (final AppLang l in AppLang.offered) {
      expect(AppLang.fromCode(l.code), l);
    }
    for (final AppLang l in AppLang.values) {
      expect(l.nativeName, isNotEmpty);
    }
    expect(AppLang.tryCode('xx'), isNull);
  });

  test('hidden languages are ready but not offered (NEW_LANGS)', () {
    expect(AppLang.de.hidden, isTrue);
    expect(AppLang.pt.hidden, isTrue);
    expect(AppLang.it.hidden, isTrue);
    expect(AppLang.nl.hidden, isTrue);
    expect(AppLang.bs.hidden, isTrue);
    expect(AppLang.sq.hidden, isTrue);
    expect(AppLang.ru.hidden, isTrue);
    expect(AppLang.sw.hidden, isTrue);
    expect(AppLang.ha.hidden, isTrue);
    expect(AppLang.af.hidden, isTrue);
    expect(AppLang.fa.hidden, isTrue);
    expect(AppLang.hi.hidden, isTrue);
    expect(AppLang.zh.hidden, isTrue);
    expect(AppLang.showHidden, isFalse);
    for (final AppLang l in AppLang.values.where((AppLang l) => l.hidden)) {
      expect(AppLang.offered, isNot(contains(l)));
      expect(SupportedLocales.all.map((Locale x) => x.languageCode),
          isNot(contains(l.code)));
      // A phone in that language, or a saved choice, gets the default.
      expect(AppLang.tryCode(l.code), isNull);
    }
    expect(AppLang.offered.where((AppLang l) => l.hidden), isEmpty);
  });

  test('every language has every string, with the same placeholders', () {
    final Map<String, dynamic> en = _arb('en');
    final List<String> keys =
        en.keys.where((String k) => !k.startsWith('@')).toList();
    for (final AppLang l in AppLang.values) {
      final Map<String, dynamic> arb = _arb(l.code);
      for (final String k in keys) {
        expect(arb.containsKey(k), isTrue, reason: '${l.code}: missing $k');
        expect(_placeholders(arb[k] as String), _placeholders(en[k] as String),
            reason: '${l.code}: placeholders differ in $k');
      }
      expect(arb.keys.where((String k) => !k.startsWith('@')).length,
          keys.length,
          reason: '${l.code} has keys English does not');
    }
  });

  test('long texts exist (or fall back to English) in every language', () {
    for (final AppLang l in AppLang.values) {
      expect(MonthNames.full(lang: l), hasLength(12));
      expect(MonthNames.short(lang: l), hasLength(12));
      expect(GuideContent.topics(lang: l).length,
          GuideContent.topics(lang: AppLang.en).length);
      for (final LegalDoc doc in LegalDoc.values) {
        expect(LegalContent.sections(doc, lang: l).length,
            LegalContent.sections(doc, lang: AppLang.en).length);
      }
      if (l.rtl) continue; // Arabic and Urdu use the Arabic script
      for (final TransactionType t in TransactionType.values) {
        for (final String c in Catalog.categoriesFor(t)) {
          expect(_arabicLetters.hasMatch(Catalog.label(c, lang: l)), isFalse,
              reason: '${l.code}: $c');
        }
      }
    }
  });

  test('the database catalog lists every currency the app offers', () {
    final String sql = File('supabase/setup_all.sql').readAsStringSync();
    final String schema = File('supabase/schema.sql').readAsStringSync();
    for (final Currency c in Currencies.all) {
      expect(sql, contains("('${c.code}', "), reason: 'setup_all.sql: ${c.code}');
      expect(schema, contains("('${c.code}', "), reason: 'schema.sql: ${c.code}');
    }
  });
}
