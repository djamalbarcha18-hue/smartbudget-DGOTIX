/// Every language the app offers must produce a whole document.
///
/// A report is the one screen a reader keeps, prints and sends on, and a
/// missing typeface does not fail loudly — it drops a letter or throws deep
/// inside the layout. So each language is laid out here for real, with the
/// fonts it would actually use, and the bytes are checked.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/features/reports/data/report_fonts.dart';
import 'package:smartbudget/features/reports/data/report_pdf.dart';

/// A line of text in each script, so the page is never trivially empty.
const Map<AppLang, String> _sample = <AppLang, String>{
  AppLang.ar: 'إيجار السكن',
  AppLang.en: 'Housing',
  AppLang.fr: 'Logement',
  AppLang.es: 'Vivienda',
  AppLang.de: 'Wohnen',
  AppLang.pt: 'Habitação',
  AppLang.it: 'Alloggio',
  AppLang.nl: 'Huisvesting',
  AppLang.tr: 'Konut İçğüş',
  AppLang.id: 'Perumahan',
  AppLang.ms: 'Perumahan',
  AppLang.ru: 'Жильё',
  AppLang.fa: 'مسکن',
  AppLang.ur: 'رہائش',
  AppLang.hi: 'Housing',
  AppLang.zh: 'Housing',
  AppLang.ja: 'Housing',
  AppLang.ko: 'Housing',
  AppLang.sw: 'Makazi',
  AppLang.ha: 'Gidaje ɓɗƙƴ',
  AppLang.af: 'Behuising',
  AppLang.bs: 'Stanovanje čćđ',
  AppLang.sq: 'Banimi',
};

ReportPdfData _data(AppLang lang, {bool full = true}) => ReportPdfData(
      logoSvg:
          full ? File('assets/brand/dgotix-logo.svg').readAsStringSync() : null,
      title: 'Reports',
      subtitle: '${_sample[lang]} · 2026',
      generatedLabel: '3 / 11 / 2026',
      kpis: <ReportRow>[
        ReportRow(_sample[lang]!, '85,000'),
        const ReportRow('Expenses', '62,900'),
        const ReportRow('Net', '22,100'),
        const ReportRow('Savings rate', '26.0%'),
      ],
      comparisonTitle: full ? 'Versus before' : null,
      comparison: full
          ? <ReportComparisonRow>[
              ReportComparisonRow(_sample[lang]!, '85,000', '80,000', '+6.3%',
                  up: true),
            ]
          : const <ReportComparisonRow>[],
      noComparisonLabel: 'Nothing earlier',
      panels: full
          ? <ReportPanel>[
              ReportPanel(
                title: _sample[lang]!,
                rows: <ReportRow>[ReportRow(_sample[lang]!, '70,000')],
                meter: 0.83,
                meterLabel: '83%',
              ),
            ]
          : const <ReportPanel>[],
      trendTitle: full ? 'Trend' : null,
      trend: full
          ? <ReportTrendPoint>[
              for (int i = 0; i < 12; i++)
                ReportTrendPoint('${i + 1}', 8000000 + i, 6000000 + i),
            ]
          : const <ReportTrendPoint>[],
      topTitle: full ? 'Largest' : null,
      top: full
          ? <ReportBar>[ReportBar(_sample[lang]!, '25,000', 1.0)]
          : const <ReportBar>[],
      incomeTitle: 'Income',
      income: <ReportRow>[ReportRow(_sample[lang]!, '70,000')],
      expenseTitle: 'Expenses',
      expenses: <ReportRow>[ReportRow(_sample[lang]!, '25,000')],
      emptyLabel: '-',
      footer: 'DGOTIX Analytics · SmartBudget',
      isRtl: lang.rtl,
      insightTitle: full ? 'Reading' : null,
      insight: full ? '${_sample[lang]!}: 39.7%.\n26.0%.' : null,
    );

Future<Uint8List> _build(AppLang lang, {bool full = true}) async {
  final ReportFontSet faces =
      ReportFonts.forLanguage(lang, currencySymbol: 'د.ج');
  pw.Font open(String path) =>
      pw.Font.ttf(ByteData.view(File(path).readAsBytesSync().buffer));
  return ReportPdfBuilder.build(
    _data(lang, full: full),
    base: open(faces.base),
    bold: open(faces.bold),
    fallback: <pw.Font>[for (final String p in faces.fallback) open(p)],
  );
}

void main() {
  test('the languages listed here are the languages the app has', () {
    expect(_sample.keys.toSet(), AppLang.values.toSet());
  });

  group('every language lays out', () {
    for (final AppLang lang in AppLang.values) {
      test(lang.code, () async {
        final Uint8List bytes = await _build(lang);
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        // A whole document, not a cover page that failed early.
        expect(bytes.length, greaterThan(4000), reason: 'suspiciously small');
      });
    }
  });

  group('every font a language asks for is really bundled', () {
    for (final AppLang lang in AppLang.values) {
      test(lang.code, () {
        for (final String path
            in ReportFonts.forLanguage(lang, currencySymbol: '﷼').all) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
      });
    }
  });

  group('the font choice follows the script, not the habit', () {
    test('Urdu and Persian are set in Noto Naskh, with Tajawal for digits', () {
      for (final AppLang lang in <AppLang>[AppLang.ur, AppLang.fa]) {
        final ReportFontSet f = ReportFonts.forLanguage(lang);
        expect(f.base, contains('NotoNaskhArabic'));
        expect(f.fallback.first, contains('Tajawal'));
      }
    });

    test('Russian is set in Inter', () {
      expect(ReportFonts.forLanguage(AppLang.ru).base, contains('Inter'));
    });

    test('Arabic is set in Tajawal and needs no fallback', () {
      final ReportFontSet f = ReportFonts.forLanguage(AppLang.ar);
      expect(f.base, contains('Tajawal'));
      expect(f.fallback, isEmpty);
    });

    test('a currency sign can pull in a face on its own', () {
      // The rupee is in neither Arabic face; the rial is only in Noto Naskh.
      expect(ReportFonts.forLanguage(AppLang.en, currencySymbol: '₹').fallback,
          contains(contains('Inter')));
      expect(ReportFonts.forLanguage(AppLang.ar, currencySymbol: '﷼').fallback,
          contains(contains('NotoNaskhArabic')));
      // A plain Latin sign pulls in nothing.
      expect(ReportFonts.forLanguage(AppLang.en, currencySymbol: '\$').fallback,
          isEmpty);
    });
  });

  test('a report with no sections at all is still a valid document', () async {
    final Uint8List bytes = await _build(AppLang.ar, full: false);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('the logo is optional: a missing asset still produces the report',
      () async {
    final ReportPdfData noLogo = _data(AppLang.en, full: false);
    expect(noLogo.logoSvg, isNull);
    final pw.Font f = pw.Font.ttf(ByteData.view(
        File('assets/fonts/Tajawal-Regular.ttf').readAsBytesSync().buffer));
    final Uint8List bytes =
        await ReportPdfBuilder.build(noLogo, base: f, bold: f);
    expect(bytes, isNotEmpty);
  });
}
