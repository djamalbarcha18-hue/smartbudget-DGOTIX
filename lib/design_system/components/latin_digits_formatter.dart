import 'package:flutter/services.dart';

import 'package:smartbudget/core/l10n/latin_digits.dart';

/// Turns digits typed on an Arabic/Persian keyboard into Latin digits as the
/// user types (see [LatinDigits]). Put it FIRST in a field's formatters so
/// digit-only filters after it see Latin digits.
class LatinDigitsFormatter extends TextInputFormatter {
  const LatinDigitsFormatter();

  /// Ready-made formatter list for fields that have no other formatters.
  static const List<TextInputFormatter> only = <TextInputFormatter>[
    LatinDigitsFormatter(),
  ];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = LatinDigits.normalize(newValue.text);
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}
