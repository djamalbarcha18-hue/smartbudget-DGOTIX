import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// A consistent, RTL-aware "go back" control for sub-pages that aren't in the
/// main navigation (e.g. the legal pages). Pops the router history when there
/// is something to pop, otherwise falls back to [fallbackRoute] so the user is
/// never stranded on a page with no way out.
class DsBackButton extends StatelessWidget {
  const DsBackButton({super.key, this.fallbackRoute = '/dashboard'});

  /// Where to go when there is no history to pop back to.
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(fallbackRoute),
      icon: Icon(
        rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
        color: c.textMuted,
      ),
    );
  }
}
