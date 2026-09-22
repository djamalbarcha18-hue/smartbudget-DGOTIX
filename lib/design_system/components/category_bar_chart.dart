import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/components/donut_chart.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// A clean-by-default horizontal category bar chart. Each row shows the
/// category name and a proportional bar — but NO permanent numeric value.
/// The amount and share are revealed only for the row the user hovers, taps or
/// focuses. Selection is controlled by the parent ([selectedIndex] +
/// [onSelectionChanged]) so it can stay in sync with a sibling donut.
///
/// Reuses [DonutSegment] (label / value / color / valueLabel) so a single
/// aggregated list drives both charts.
class CategoryBarChart extends StatefulWidget {
  const CategoryBarChart({
    super.key,
    required this.segments,
    required this.total,
    this.selectedIndex,
    this.onSelectionChanged,
  });

  final List<DonutSegment> segments;

  /// Sum used to compute each row's percentage share (the grand total, which
  /// may exceed the sum of shown segments if the caller aggregated an "Other").
  final double total;

  final int? selectedIndex;
  final ValueChanged<int?>? onSelectionChanged;

  @override
  State<CategoryBarChart> createState() => _CategoryBarChartState();
}

class _CategoryBarChartState extends State<CategoryBarChart> {
  int? _hover;

  int? get _active => _hover ?? widget.selectedIndex;

  void _toggle(int i) {
    if (widget.onSelectionChanged == null) return;
    widget.onSelectionChanged!(widget.selectedIndex == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final double maxValue = widget.segments.fold<double>(
        0, (double m, DonutSegment s) => s.value > m ? s.value : m);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < widget.segments.length; i++)
          _buildRow(context, c, t, i, maxValue),
      ],
    );
  }

  Widget _buildRow(BuildContext context, DsColors c, TextTheme t, int i,
      double maxValue) {
    final DonutSegment seg = widget.segments[i];
    final bool active = _active == i;
    final bool dimmed = _active != null && !active;
    final double fill = maxValue <= 0 ? 0 : (seg.value / maxValue).clamp(0, 1);
    final int pct = widget.total <= 0
        ? 0
        : (seg.value / widget.total * 100).round();
    final Color barColor =
        seg.color.withValues(alpha: dimmed ? 0.30 : 1.0);
    final Color nameColor = dimmed ? c.textMuted : c.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = i),
      onExit: (_) => setState(() => _hover = _hover == i ? null : _hover),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _toggle(i),
        // Semantics label keeps the value available to assistive tech even
        // though it is visually revealed only on interaction.
        child: Semantics(
          label: '${seg.label}: ${seg.valueLabel ?? ''} ($pct%)',
          selected: active,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        seg.label,
                        style: t.bodySmall?.copyWith(
                          color: nameColor,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Value + share appear only for the active row → clean by
                    // default, detailed on interaction.
                    if (active) ...<Widget>[
                      const SizedBox(width: DsSpacing.sm),
                      Text(
                        seg.valueLabel ?? '',
                        style: t.labelSmall?.copyWith(
                            color: seg.color, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text('$pct%',
                          style: t.labelSmall?.copyWith(color: c.textMuted)),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 8,
                  child: LayoutBuilder(
                    builder: (BuildContext ctx, BoxConstraints cons) {
                      final double w =
                          cons.maxWidth.isFinite ? cons.maxWidth : 0;
                      return Stack(
                        children: <Widget>[
                          Container(
                            width: w,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: w * fill,
                            height: 8,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
