import 'package:flutter/material.dart';

import 'package:smartbudget/core/text/markdown_lite.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// Renders AI answers written in light Markdown (see [MarkdownLite]): real
/// bold, bullets and headings instead of raw `**` and `-`, each paragraph in
/// its own reading direction, and selectable.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.source, {super.key, this.style});

  final String source;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextStyle base = style ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textPrimary) ??
        const TextStyle();
    final List<MdBlock> blocks = MarkdownLite.parse(source);

    TextSpan spans(MdBlock b, TextStyle s) => TextSpan(
          children: <InlineSpan>[
            for (final MdSpan sp in b.spans)
              TextSpan(
                text: sp.text,
                style: sp.bold ? s.copyWith(fontWeight: FontWeight.w800) : s,
              ),
          ],
        );

    Widget block(MdBlock b) {
      final TextDirection dir = MarkdownLite.isRtl(b.raw)
          ? TextDirection.rtl
          : TextDirection.ltr;
      final Widget body = switch (b.type) {
        MdBlockType.heading => Text.rich(spans(
            b, base.copyWith(fontWeight: FontWeight.w800, fontSize: 15.5))),
        MdBlockType.paragraph => Text.rich(spans(b, base)),
        MdBlockType.bullet || MdBlockType.numbered => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 20,
                child: Text(
                  b.type == MdBlockType.bullet ? '•' : b.marker,
                  style: base.copyWith(
                      color: c.brand, fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(child: Text.rich(spans(b, base))),
            ],
          ),
      };
      return Directionality(textDirection: dir, child: body);
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < blocks.length; i++) ...<Widget>[
            if (i > 0)
              SizedBox(
                  height: blocks[i].type == MdBlockType.bullet ||
                          blocks[i].type == MdBlockType.numbered
                      ? DsSpacing.xs
                      : DsSpacing.sm),
            block(blocks[i]),
          ],
        ],
      ),
    );
  }
}
