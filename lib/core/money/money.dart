import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/currency.dart';

/// An exact monetary amount: integer minor units + a currency code.
///
/// Money is stored and computed as integers (no floating-point drift). Mixing
/// currencies in arithmetic is a programming error and throws — cross-currency
/// conversion belongs to the exchange-rate layer (a later phase), never here.
@immutable
class Money {
  const Money(this.minorUnits, this.currencyCode);

  final int minorUnits;
  final String currencyCode;

  Currency get currency => Currencies.byCode(currencyCode);

  static Money zero(String currencyCode) => Money(0, currencyCode);

  /// Build from a user-entered decimal amount (e.g. 250.5) in [currencyCode].
  factory Money.fromDouble(double amount, String currencyCode) {
    final Currency c = Currencies.byCode(currencyCode);
    return Money((amount * c.minorPerUnit).round(), currencyCode);
  }

  double get asDouble => minorUnits / currency.minorPerUnit;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currencyCode);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currencyCode);
  }

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;

  void _assertSameCurrency(Money other) {
    assert(
      other.currencyCode == currencyCode,
      'Cannot combine $currencyCode with ${other.currencyCode}; '
      'convert via the exchange-rate layer first.',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);
}
