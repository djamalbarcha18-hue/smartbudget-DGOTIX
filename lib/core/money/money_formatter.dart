import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/money/money.dart';

/// Formats [Money] for display with Latin digits and grouped thousands.
///
/// Uses the 'en' locale on purpose (Latin digits + '.' decimal), matching the
/// SmartBudget rule that numbers are always Latin regardless of UI language.
abstract final class MoneyFormatter {
  static String format(Money money, {bool withSymbol = true}) {
    final Currency c = money.currency;
    final NumberFormat f = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: c.decimals,
    );
    final String number = f.format(money.asDouble);
    // Symbol BEFORE the number (e.g. "$ 1,234.00"). The leading LRM keeps the
    // whole money string left-to-right so the symbol stays in front even inside
    // an Arabic (RTL) layout, while digits remain Latin.
    return withSymbol ? '‎${c.symbol} $number' : number;
  }

  /// Compact form for tight KPI tiles (e.g. 1.2K, 3.4M) with the symbol in front.
  static String compact(Money money) {
    final Currency c = money.currency;
    final NumberFormat f = NumberFormat.compact(locale: 'en');
    return '‎${c.symbol} ${f.format(money.asDouble)}';
  }

  /// Formats a ratio (0..1) as a Latin-digit percentage, e.g. 0.158 -> "15.8%".
  static String percent(double ratio, {int decimals = 1}) {
    final NumberFormat f = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: decimals,
    );
    return '${f.format(ratio * 100)}%';
  }
}
