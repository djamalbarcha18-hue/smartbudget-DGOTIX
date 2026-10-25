import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/money/number_style.dart';

/// Amounts typed by hand: read with or without thousands separators, in the
/// chosen [NumberStyle] ("12,500" is twelve thousand five hundred, not 12.5).
abstract final class AmountInput {
  /// The number in [text], or null when there is none. Spaces and either
  /// separator are accepted; when only one separator is typed once, it is
  /// the decimal mark unless it sits like a thousands separator of the
  /// [style] ("12,500" with 1,234.56 numbers, "12.500" with 1.234,56).
  static double? parse(String? text, {NumberStyle? style}) {
    if (text == null) return null;
    final NumberStyle st = style ?? MoneyFormatter.style;
    String s = LatinDigits.normalize(text)
        .replaceAll(RegExp(r'[\s   ٬]'), '')
        .replaceAll('٫', '.');
    if (s.isEmpty) return null;
    final int dots = '.'.allMatches(s).length;
    final int commas = ','.allMatches(s).length;
    String? decimal;
    if (dots > 0 && commas > 0) {
      // Both: the last one is the decimal mark.
      decimal = s.lastIndexOf('.') > s.lastIndexOf(',') ? '.' : ',';
    } else if (dots + commas == 1) {
      final String sep = dots == 1 ? '.' : ',';
      final int at = s.indexOf(sep);
      final bool looksGrouped = s.length - at - 1 == 3 && at >= 1 && at <= 3;
      decimal = looksGrouped && sep == st.group ? null : sep;
    } else if (dots + commas > 1) {
      // The same mark more than once: thousands separators.
      decimal = null;
    }
    final String grouping =
        decimal == null ? '[.,]' : (decimal == '.' ? ',' : r'\.');
    s = s.replaceAll(RegExp(grouping), '');
    if (decimal == ',') s = s.replaceAll(',', '.');
    if (!RegExp(r'^-?\d*\.?\d+$').hasMatch(s) &&
        !RegExp(r'^-?\d+\.?$').hasMatch(s)) {
      return null;
    }
    return double.tryParse(s);
  }

  /// [value] as a field's starting text: no thousands separators, the
  /// style's decimal mark ("1250", "12,5").
  static String text(double value, {NumberStyle? style}) {
    final NumberStyle st = style ?? MoneyFormatter.style;
    final String plain = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    return plain.replaceAll('.', st.decimal);
  }
}
