import 'package:flutter/material.dart';

/// The «go on» arrow at the end of a row: points right in left-to-right
/// languages and left in Arabic, Urdu and Persian. The direction is chosen
/// here and the icon is drawn as is, so it can't be flipped twice.
class ForwardChevron extends StatelessWidget {
  const ForwardChevron({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: size,
      color: color,
      textDirection: TextDirection.ltr,
    );
  }
}
