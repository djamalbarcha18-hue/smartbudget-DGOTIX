/// Exact money arithmetic for the zakat engine: integers only (minor units,
/// BigInt for products), decimal strings parsed without floating point, and
/// rounding done once, in the open.
library;

import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';

abstract final class ZakatMoney {
  /// Decimals of [code] (ISO 4217), or null for a currency the app doesn't
  /// know: the engine refuses it instead of guessing (Currencies.byCode would
  /// silently answer USD).
  static int? decimalsOf(String code) {
    for (final Currency c in Currencies.all) {
      if (c.code == code) return c.decimals;
    }
    return null;
  }

  static BigInt pow10(int n) => BigInt.from(10).pow(n);

  /// numerator / denominator rounded to an integer by [policy] (works for
  /// negative values too: halfUp rounds half away from zero).
  static int divide(BigInt numerator, BigInt denominator, RoundingPolicy policy) {
    if (denominator == BigInt.zero) {
      throw ArgumentError('division by zero');
    }
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final BigInt q = numerator ~/ denominator; // truncates toward zero
    final BigInt r = numerator.remainder(denominator);
    if (r == BigInt.zero) return q.toInt();
    final bool negative = numerator.isNegative;
    switch (policy) {
      case RoundingPolicy.down:
        return (negative ? q - BigInt.one : q).toInt();
      case RoundingPolicy.up:
        return (negative ? q : q + BigInt.one).toInt();
      case RoundingPolicy.halfUp:
        final bool half = r.abs() * BigInt.two >= denominator;
        if (!half) return q.toInt();
        return (negative ? q - BigInt.one : q + BigInt.one).toInt();
    }
  }

  /// A non-negative decimal string ("147.25", "27000") as an integer scaled
  /// by 10^[scale]; null when it isn't one or has more decimals than [scale].
  static BigInt? parseScaled(String text, int scale) {
    final String s = text.trim();
    final RegExpMatch? m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(s);
    if (m == null) return null;
    final String whole = m.group(1)!;
    final String frac = m.group(2) ?? '';
    if (frac.length > scale) return null;
    return BigInt.parse(whole + frac.padRight(scale, '0'));
  }
}

/// How many units of the base currency one unit of [from] is worth on
/// [asOf], with where the rate came from. The rate is kept as an exact
/// decimal (scaled by 10^[scale]), never a double.
class FxQuote {
  const FxQuote({
    required this.from,
    required this.to,
    required this.rateScaled,
    required this.asOf,
    required this.source,
    this.scale = 8,
  });

  /// From a decimal string ("147.25"): null when it isn't a positive number.
  static FxQuote? parse({
    required String from,
    required String to,
    required String rate,
    required DateTime asOf,
    required String source,
  }) {
    final BigInt? r = ZakatMoney.parseScaled(rate, 8);
    if (r == null || r <= BigInt.zero) return null;
    return FxQuote(
        from: from, to: to, rateScaled: r, asOf: asOf, source: source);
  }

  final String from;
  final String to;
  final BigInt rateScaled;
  final int scale;
  final DateTime asOf;
  final String source;

  /// [minor] units of [from] in minor units of [to].
  int convert(int minor, RoundingPolicy rounding) {
    final int df = ZakatMoney.decimalsOf(from)!;
    final int dt = ZakatMoney.decimalsOf(to)!;
    final BigInt num = BigInt.from(minor) * rateScaled * ZakatMoney.pow10(dt);
    final BigInt den = ZakatMoney.pow10(df) * ZakatMoney.pow10(scale);
    return ZakatMoney.divide(num, den, rounding);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'from': from,
        'to': to,
        'rateScaled': rateScaled.toString(),
        'scale': scale,
        'asOf': asOf.toIso8601String(),
        'source': source,
      };

  static FxQuote? fromJson(Map<String, dynamic> j) {
    final BigInt? r = BigInt.tryParse('${j['rateScaled']}');
    final DateTime? at = DateTime.tryParse('${j['asOf']}');
    if (r == null || at == null) return null;
    return FxQuote(
      from: '${j['from']}',
      to: '${j['to']}',
      rateScaled: r,
      scale: (j['scale'] as num?)?.toInt() ?? 8,
      asOf: at,
      source: '${j['source'] ?? ''}',
    );
  }
}
