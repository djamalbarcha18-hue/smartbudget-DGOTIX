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
    return withSymbol ? '$number ${c.symbol}' : number;
  }

  /// Compact form for tight KPI tiles (e.g. 1.2K, 3.4M) with symbol.
  static String compact(Money money) {
    final Currency c = money.currency;
    final NumberFormat f = NumberFormat.compact(locale: 'en');
    return '${f.format(money.asDouble)} ${c.symbol}';
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
