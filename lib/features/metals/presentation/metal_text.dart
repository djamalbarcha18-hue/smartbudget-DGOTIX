import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// How metals are named and shown.
abstract final class MetalText {
  static String name(AppLocalizations l, Metal m) => switch (m) {
        Metal.gold => l.metalGold,
        Metal.silver => l.metalSilver,
        Metal.platinum => l.metalPlatinum,
        Metal.palladium => l.metalPalladium,
      };

  /// «21 karat» for gold, «925» for the others.
  static String purity(AppLocalizations l, Metal m, int p) =>
      m == Metal.gold ? l.metalKarat(p) : '$p';

  /// A weight in grams, with the decimals it has (up to 2) and the user's
  /// decimal mark.
  static String grams(AppLocalizations l, double g) {
    String s = g.toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return l.metalGrams(s.replaceAll('.', MoneyFormatter.style.decimal));
  }
}
