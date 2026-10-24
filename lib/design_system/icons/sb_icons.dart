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

  // The trip items (Lucide line icons, see tool/build_icon_font.py).
  static const IconData tripFlights = IconData(0xe002, fontFamily: _family);
  static const IconData tripStay = IconData(0xe003, fontFamily: _family);
  static const IconData tripFood = IconData(0xe004, fontFamily: _family);
  static const IconData tripTransport = IconData(0xe005, fontFamily: _family);
  static const IconData tripActivities = IconData(0xe006, fontFamily: _family);
  static const IconData tripGifts = IconData(0xe007, fontFamily: _family);
  static const IconData tripEmergency = IconData(0xe008, fontFamily: _family);
  static const IconData tripOther = IconData(0xe009, fontFamily: _family);
}
