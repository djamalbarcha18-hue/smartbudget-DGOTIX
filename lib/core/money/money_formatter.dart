import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/number_style.dart';

/// Formats [Money] for display with Latin digits and grouped thousands.
///
/// Uses the 'en' locale on purpose (Latin digits), matching the SmartBudget
/// rule that numbers are always Latin regardless of UI language; the
/// separators follow the [style] the user chose in Settings.
abstract final class MoneyFormatter {
  /// The user's [NumberStyle]; set by the app from Settings.
  static NumberStyle style = NumberStyle.commaDot;

  static String format(Money money, {bool withSymbol = true}) {
    final Currency c = money.currency;
    final NumberFormat f = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: c.decimals,
    );
    final String number = style.apply(f.format(money.asDouble));
    // Symbol BEFORE the number (e.g. "$ 1,234.00"). The leading LRM keeps the
    // whole money string left-to-right so the symbol stays in front even inside
    // an Arabic (RTL) layout, while digits remain Latin.
    return withSymbol ? '‎${c.symbol} $number' : number;
  }

  /// Compact form for tight KPI tiles (e.g. 1.2K, 3.4M) with the symbol in front.
  static String compact(Money money) {
    final Currency c = money.currency;
    final NumberFormat f = NumberFormat.compact(locale: 'en');
    return '‎${c.symbol} ${style.apply(f.format(money.asDouble))}';
  }

  /// Formats a ratio (0..1) as a Latin-digit percentage, e.g. 0.158 -> "15.8%".
  static String percent(double ratio, {int decimals = 1}) {
    final NumberFormat f = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: decimals,
    );
    return '${style.apply(f.format(ratio * 100))}%';
  }
}
