import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// The core surface of the DGOTIX design system: a moderate glassmorphism card.
///
/// Semi-transparent fill + light backdrop blur + hairline border + soft shadow
/// + a 1px inner top highlight for the "glass edge". Deliberately restrained
/// (premium FinTech, not gaming UI).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DsSpacing.lg),
    this.borderRadius = DsRadius.brLg,
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  /// Optional accent color for a subtle top border (used e.g. to color a KPI
  /// tile by its semantic — income/expense/…).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final DsGlass g = context.dsGlass;

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: g.shadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: g.blur,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[g.fillTop, g.fill],
              ),
              border: Border.all(color: g.borderColor),
            ),
            child: _Highlight(
              color: g.highlight,
              borderRadius: borderRadius,
              accent: accent,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: surface,
      ),
    );
  }
}

/// Paints the 1px inner top highlight (and optional accent bar) via a border.
class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.child,
    required this.color,
    required this.borderRadius,
    this.accent,
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border(
          top: BorderSide(color: accent ?? color, width: accent != null ? 2 : 1),
        ),
      ),
      child: child,
    );
  }
}
