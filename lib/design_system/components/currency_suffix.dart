import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// A currency code shown at the end of an amount field, always visible (unlike
/// `suffixText`, which hides until the field is focused or filled), so the
/// user knows which currency they're typing in. Use as `suffixIcon`.
class CurrencySuffix extends StatelessWidget {
  const CurrencySuffix(this.code, {super.key});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8, end: 14),
        child: Text(
          code,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: context.dsColors.textMuted),
        ),
      ),
    );
  }
}
