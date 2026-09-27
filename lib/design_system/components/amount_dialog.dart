import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/currency_suffix.dart';
import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Asks for one positive amount, in [currency] when given (shown in the
/// field). Returns null when cancelled or invalid.
Future<double?> showAmountDialog(
  BuildContext context, {
  required String title,
  double? initial,
  String? currency,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final TextEditingController amount = TextEditingController(
      text: initial == null ? '' : _plain(initial));
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        inputFormatters: LatinDigitsFormatter.only,
        controller: amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l.fieldAmount,
          suffixIcon: currency == null ? null : CurrencySuffix(currency),
        ),
        onSubmitted: (_) => Navigator.of(ctx).pop(true),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.save),
        ),
      ],
    ),
  );
  final double n =
      double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
  amount.dispose();
  return ok == true && n > 0 ? n : null;
}

/// Parses a user-typed amount ("1 250,5" → 1250.5); null when not positive.
double? parseAmount(String raw) {
  final double? n =
      double.tryParse(raw.trim().replaceAll(' ', '').replaceAll(',', '.'));
  return n != null && n > 0 ? n : null;
}

String _plain(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
