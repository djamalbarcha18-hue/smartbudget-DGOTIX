import 'package:flutter/material.dart';

import 'package:smartbudget/core/money/currency.dart';

/// A small rounded flag image for a currency, for quick visual switching.
///
/// Flags are bundled PNGs (assets/flags/<country>.png). If an asset is missing
/// it degrades gracefully to a neutral globe glyph rather than throwing.
class CurrencyFlag extends StatelessWidget {
  const CurrencyFlag(this.currency, {super.key, this.width = 24});

  /// Convenience: resolve by currency code (falls back to USD if unknown).
  CurrencyFlag.code(String code, {super.key, this.width = 24})
      : currency = Currencies.byCode(code);

  final Currency currency;
  final double width;

  @override
  Widget build(BuildContext context) {
    final double height = width * 3 / 4; // flags are 4:3
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        currency.flagAsset,
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
