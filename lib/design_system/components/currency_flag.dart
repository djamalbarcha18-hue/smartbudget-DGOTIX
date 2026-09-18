import 'package:flutter/material.dart';

import 'package:smartbudget/core/money/currency.dart';

/// A small rounded flag image, for quick visual switching between currencies
/// and country markets.
///
/// Flags are bundled PNGs (assets/flags/<country>.png). If an asset is missing
/// it degrades gracefully to a neutral globe glyph rather than throwing.
class CurrencyFlag extends StatelessWidget {
  /// From a [Currency] (uses its country).
  CurrencyFlag(Currency currency, {super.key, this.width = 24})
      : countryCode = currency.country;

  /// From a currency code (falls back to USD if unknown).
  CurrencyFlag.code(String code, {super.key, this.width = 24})
      : countryCode = Currencies.byCode(code).country;

  /// From a raw ISO 3166-1 alpha-2 country code (e.g. 'dz', 'ar', 'ng').
  const CurrencyFlag.country(this.countryCode, {super.key, this.width = 24});

  final String countryCode;
  final double width;

  @override
  Widget build(BuildContext context) {
    final double height = width * 3 / 4; // flags are 4:3
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/flags/$countryCode.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.public_outlined, size: width * 0.72),
        ),
      ),
    );
  }
}
