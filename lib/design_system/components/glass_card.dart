import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// The core surface of the DGOTIX design system: a premium glass card.
///
/// A translucent gradient fill over the ambient backdrop, a light backdrop blur,
/// a hairline border, a soft top highlight and an ambient shadow. On pointer
/// devices it lifts slightly and its border warms to the accent on hover
/// (skipped when the platform asks for reduced motion).
///
/// Blurs are drawn with [BackdropFilter.grouped], so every card inside the
/// app shell's `BackdropGroup` shares one backdrop pass — far cheaper on the
/// web than one independent blur per card.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DsSpacing.lg),
    this.borderRadius = DsRadius.brLg,
    this.onTap,
    this.accent,
    this.tintBorder = false,
    this.hoverable = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  /// Optional accent: tints the thin top edge line (no glow).
  final Color? accent;

  /// Also tint the card's border with [accent] (used to mark income, expense
  /// and balance cards with their universal colors).
  final bool tintBorder;

  /// Whether the card reacts to hover. Disable for very large containers.
  final bool hoverable;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hover = false;

  void _setHover(bool v) {
    if (_hover != v) setState(() => _hover = v);
  }

  @override
  Widget build(BuildContext context) {
    final DsGlass g = context.dsGlass;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bool lifted = _hover && widget.hoverable;
    final BorderRadius br = widget.borderRadius;
    final Color? accent = widget.accent;

    final Widget content = Stack(
      // Pass the card's constraints straight to the content, exactly as a
      // plain container would (the decorations are positioned overlays).
      fit: StackFit.passthrough,
      children: <Widget>[
        // Top edge: a highlight line (accent-tinted when an accent is set).
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    (accent ?? g.highlight).withValues(alpha: 0),
                    accent?.withValues(alpha: 0.6) ?? g.highlight,
                    (accent ?? g.highlight).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(padding: widget.padding, child: widget.child),
      ],
    );

    Widget surface = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: lifted && !reduceMotion
          ? Matrix4.translationValues(0, -2, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: lifted ? g.hoverShadow : g.shadow,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter.grouped(
          filter: g.blur,
          child: AnimatedContainer(
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: <Color>[g.fillTop, g.fill],
              ),
              border: Border.all(
                color: (widget.tintBorder && accent != null)
                    ? accent.withValues(alpha: lifted ? 0.75 : 0.45)
                    : (lifted ? g.hoverBorder : g.borderColor),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: br,
          child: surface,
        ),
      );
    }
    if (!widget.hoverable) return surface;
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: surface,
    );
  }
}
