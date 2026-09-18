import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// Renders a title where every occurrence of the "DGOTIX" wordmark is tinted
/// with the brand color, while the rest uses the base text color.
///
/// Used sparingly to badge the premium "intelligence" surfaces (Insights,
/// Analytics, AI) as DGOTIX products — brand presence without repetition.
class BrandedTitle extends StatelessWidget {
  const BrandedTitle(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static const String _token = 'DGOTIX';

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextStyle base =
        (style ?? Theme.of(context).textTheme.headlineSmall ?? const TextStyle())
            .copyWith(color: style?.color ?? c.textPrimary);
    final TextStyle brand = base.copyWith(
      color: c.brand,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );

    final List<TextSpan> spans = <TextSpan>[];
    int i = 0;
    while (i < text.length) {
      final int idx = text.indexOf(_token, i);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(i), style: base));
        break;
      }
      if (idx > i) {
        spans.add(TextSpan(text: text.substring(i, idx), style: base));
      }
      spans.add(TextSpan(text: _token, style: brand));
      i = idx + _token.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      style: base,
      overflow: TextOverflow.ellipsis,
    );
  }
}
