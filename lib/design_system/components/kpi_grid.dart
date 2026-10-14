import 'package:flutter/widgets.dart';

import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// Lays out KPI cards in equal columns: as many as fit at [minTileWidth]
/// (up to [maxColumns]), and never fewer than two, so a phone shows them in
/// pairs. A last card left alone on its row takes the full width.
class KpiGrid extends StatelessWidget {
  const KpiGrid({
    super.key,
    required this.children,
    this.minTileWidth = 220,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = DsSpacing.gridGap;
        final int fit =
            ((constraints.maxWidth + gap) / (minTileWidth + gap)).floor();
        final int cols = fit.clamp(2, maxColumns).clamp(1, children.length);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int start = 0; start < children.length; start += cols) ...<Widget>[
              if (start > 0) const SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = start;
                      i < start + cols && i < children.length;
                      i++) ...<Widget>[
                    if (i > start) const SizedBox(width: gap),
                    Expanded(child: children[i]),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
