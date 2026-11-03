/// Which bundled typefaces a report is set in, by language and currency.
///
/// Pure path logic, so a test can load the same files from disk and prove
/// every language the app offers produces a document. The widget turns these
/// paths into fonts through the asset bundle; nothing here touches Flutter.
library;

import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';

@immutable
class ReportFontSet {
  const ReportFontSet({
    required this.base,
    required this.bold,
    required this.fallback,
  });

  final String base;
  final String bold;

  /// Only where letters would otherwise be missing: every extra font is
  /// bytes in the exported file.
  final List<String> fallback;

  List<String> get all => <String>[base, bold, ...fallback];
}

abstract final class ReportFonts {
  static const String _tajawal = 'assets/fonts/Tajawal';
  static const String _naskh = 'assets/fonts/NotoNaskhArabic';
  static const String _inter = 'assets/google_fonts/Inter';

  /// The rial (﷼) and afghani (؋) signs, which Tajawal and Inter lack.
  static bool needsNaskh(String symbol) =>
      symbol.contains('﷼') || symbol.contains('؋');

  /// A currency sign with a character beyond Latin-1, Arabic and €.
  static bool needsInter(String symbol) => symbol.runes.any((int r) =>
      r > 0xFF &&
      (r < 0x0600 || r > 0x06FF) &&
      r != 0x20AC &&
      !needsNaskh(String.fromCharCode(r)));

  /// [currencySymbol] is the base currency's sign as the report will print
  /// it: a ₹ or a ﷼ decides a fallback on its own, whatever the language.
  static ReportFontSet forLanguage(AppLang lang, {String currencySymbol = ''}) {
    // Cyrillic is in neither Arabic face: Russian reports are set in Inter.
    if (lang == AppLang.ru) {
      return const ReportFontSet(
        base: '$_inter-Regular.ttf',
        bold: '$_inter-SemiBold.ttf',
        // Arabic can still appear in a Russian report — a category the
        // reader typed, or an Arabic currency sign.
        fallback: <String>['$_tajawal-Regular.ttf'],
      );
    }

    // Urdu and Persian letters are not in Tajawal.
    final String family = lang.naskh ? _naskh : _tajawal;

    // Turkish ğ ş İ, Bosnian č ć đ, Hausa ɓ ɗ ƙ ƴ.
    final bool interLetters = switch (lang) {
      AppLang.tr || AppLang.bs || AppLang.ha => true,
      _ => false,
    };

    return ReportFontSet(
      base: '$family-Regular.ttf',
      bold: '$family-Bold.ttf',
      fallback: <String>[
        // Digits and Latin for Urdu and Persian reports.
        if (lang.naskh) '$_tajawal-Regular.ttf',
        if (interLetters || needsInter(currencySymbol)) '$_inter-Regular.ttf',
        if (!lang.naskh && needsNaskh(currencySymbol)) '$_naskh-Regular.ttf',
      ],
    );
  }
}
