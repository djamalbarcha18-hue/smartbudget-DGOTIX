import 'package:intl/intl.dart';

/// SmartBudget shows every number — amounts, dates, counts — in Latin digits
/// (0123456789), whatever the interface language.
///
/// Money and percentages already format with the 'en' locale. This covers the
/// rest: date formatting that would otherwise use Eastern Arabic digits
/// (٠١٢٣…), notably Flutter's Arabic date picker, and digits typed on an Arabic
/// or Persian keyboard.
abstract final class LatinDigits {
  /// Locales whose date data may default to native (non-Latin) digits.
  static const List<String> _nativeDigitLocales = <String>[
    'ar', 'ar_AE', 'ar_BH', 'ar_EG', 'ar_IQ', 'ar_JO', 'ar_KW', 'ar_LB', //
    'ar_OM', 'ar_PS', 'ar_QA', 'ar_SA', 'ar_SD', 'ar_SY', 'ar_YE', 'ar_XB',
    'fa', 'ur',
  ];

  /// Makes every date formatter use Latin digits. Call once before `runApp`,
  /// so it applies to formatters created afterwards (including the ones the
  /// Material localizations build).
  static void enforce() {
    for (final String l in _nativeDigitLocales) {
      DateFormat.useNativeDigitsByDefaultFor(l, false);
    }
  }

  static const int _latinZero = 0x30;

  /// Replaces Eastern Arabic (٠-٩) and Persian (۰-۹) digits with Latin ones,
  /// and the Arabic decimal/thousands separators (٫ ٬) with '.' and ','.
  /// One character in, one character out, so text positions are unchanged.
  static String normalize(String input) {
    StringBuffer? out;
    for (int i = 0; i < input.length; i++) {
      final int u = input.codeUnitAt(i);
      int? r;
      if (u >= 0x0660 && u <= 0x0669) {
        r = _latinZero + (u - 0x0660);
      } else if (u >= 0x06F0 && u <= 0x06F9) {
        r = _latinZero + (u - 0x06F0);
      } else if (u == 0x066B) {
        r = 0x2E; // ٫ → .
      } else if (u == 0x066C) {
        r = 0x2C; // ٬ → ,
      }
      if (r != null) {
        out ??= StringBuffer(input.substring(0, i));
        out.writeCharCode(r);
      } else {
        out?.writeCharCode(u);
      }
    }
    return out?.toString() ?? input;
  }
}
