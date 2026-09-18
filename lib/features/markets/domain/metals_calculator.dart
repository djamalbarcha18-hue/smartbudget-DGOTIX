/// Pure precious-metals math (unit-tested). No prices are hardcoded here — the
/// caller passes a live spot price and these functions derive units/karats.
abstract final class MetalsCalculator {
  /// Grams in one troy ounce.
  static const double troyOunceGrams = 31.1034768;

  /// Gold karats (24 = pure) shown for gold.
  static const List<int> goldKarats = <int>[24, 22, 21, 20, 18, 14, 12, 10, 9];

  /// Silver fineness (per mille) shown for silver.
  static const List<int> silverFineness = <int>[999, 925, 900, 800];

  static double perGram(double perTroyOunce) => perTroyOunce / troyOunceGrams;

  static double perKilogram(double perTroyOunce) => perGram(perTroyOunce) * 1000;

  /// Karat price from the 24K price: `price24k × karat / 24`.
  static double karatPrice(double price24k, int karat) => price24k * karat / 24;

  /// Fineness price (e.g. 925/1000): `priceFine × fineness / 1000`.
  static double finenessPrice(double priceFine, int fineness) =>
      priceFine * fineness / 1000;

  static double perPound(double perTonne) => perTonne / 2204.62262185;
  static double perKgFromTonne(double perTonne) => perTonne / 1000;
}
