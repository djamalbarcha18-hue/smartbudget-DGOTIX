import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_typography.dart';

/// Readability on a phone. Below [DsBreakpoints.mobile] wide:
/// - text is drawn at [DsTypography.compactSizes] (body 15.5, secondary 14,
///   card titles 19–21);
/// - icons, and the few labels with a fixed size, grow by
///   [DsTypography.compactScale];
/// - icon buttons are at least 44×44 to press.
/// Tablets and desktops are left exactly as they were. Colours, glass and
/// layout direction are not touched; the phone's own font-size setting still
/// applies on top.
class DsReadable extends StatefulWidget {
  const DsReadable({super.key, required this.child});

  final Widget child;

  /// The least size of something to press on a phone.
  static const double minTapTarget = 44;

  @override
  State<DsReadable> createState() => _DsReadableState();
}

class _DsReadableState extends State<DsReadable> {
  ThemeData? _from;
  ThemeData? _compact;

  ThemeData _compactOf(ThemeData theme) {
    if (identical(theme, _from) && _compact != null) return _compact!;
    _from = theme;
    return _compact = theme.copyWith(
      textTheme: DsTypography.compact(theme.textTheme),
      // Icons follow the text scaler, so one factor sizes them all.
      iconTheme: theme.iconTheme.copyWith(applyTextScaling: true),
      primaryIconTheme:
          theme.primaryIconTheme.copyWith(applyTextScaling: true),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
              DsReadable.minTapTarget, DsReadable.minTapTarget),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    if (!DsBreakpoints.isMobile(mq.size.width)) return widget.child;
    return MediaQuery(
      data: mq.copyWith(
          textScaler:
              _BoostedScaler(mq.textScaler, DsTypography.compactScale)),
      child: Theme(
        data: _compactOf(Theme.of(context)),
        child: widget.child,
      ),
    );
  }
}

/// The phone's own text scaler, with everything [factor] larger.
class _BoostedScaler extends TextScaler {
  const _BoostedScaler(this.inner, this.factor);

  final TextScaler inner;
  final double factor;

  @override
  double scale(double fontSize) => inner.scale(fontSize * factor);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => inner.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _BoostedScaler && other.inner == inner && other.factor == factor;

  @override
  int get hashCode => Object.hash(inner, factor);
}
