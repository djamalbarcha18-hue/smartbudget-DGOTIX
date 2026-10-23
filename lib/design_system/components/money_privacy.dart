import 'package:flutter/widgets.dart';

/// Tells money widgets (KPI cards) below it whether to mask their figures,
/// and how to flip that from the eye button on the card.
///
/// With no [MoneyPrivacy] above it, a card always shows its figure and has no
/// eye button — the design system itself doesn't know about settings.
class MoneyPrivacy extends InheritedWidget {
  const MoneyPrivacy({
    super.key,
    required this.masked,
    required this.onToggle,
    required this.hideLabel,
    required this.showLabel,
    required this.peekHint,
    required super.child,
  });

  final bool masked;
  final VoidCallback onToggle;

  /// Tooltips for the eye button and the screen-reader text of a hidden figure.
  final String hideLabel;
  final String showLabel;
  final String peekHint;

  /// What a hidden figure shows: always the same length, so it gives away
  /// nothing about the amount.
  static const String mask = '•••••';

  static MoneyPrivacy? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MoneyPrivacy>();

  @override
  bool updateShouldNotify(MoneyPrivacy old) =>
      masked != old.masked ||
      hideLabel != old.hideLabel ||
      showLabel != old.showLabel ||
      peekHint != old.peekHint;
}
