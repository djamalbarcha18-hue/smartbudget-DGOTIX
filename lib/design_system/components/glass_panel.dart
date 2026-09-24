import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';

/// A structural glass surface (sidebar, top bar): the denser [DsGlass]
/// `fillStrong`, a hairline border and the soft top highlight, without the
/// card's hover behavior. Shares the shell's grouped backdrop blur.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = DsRadius.brXl,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final DsGlass g = context.dsGlass;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: g.shadow),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter.grouped(
          filter: g.blur,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: <Color>[g.fillTop, g.fillStrong],
              ),
              border: Border.all(color: g.borderColor),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
