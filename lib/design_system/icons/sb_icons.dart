import 'package:flutter/widgets.dart';

/// SmartBudget's own icons, from assets/fonts/icons/SbIcons.ttf (built by
/// tool/build_icon_font.py). Use them like Material's `Icons.*`.
abstract final class SbIcons {
  static const String _family = 'SbIcons';

  /// Money box: a jar with a coin going into the slot of its lid. Used for
  /// saving everywhere instead of Material's pig-shaped "savings" icon.
  static const IconData moneyBox = IconData(0xe000, fontFamily: _family);

  /// Filled variant of [moneyBox].
  static const IconData moneyBoxFilled = IconData(0xe001, fontFamily: _family);
}
