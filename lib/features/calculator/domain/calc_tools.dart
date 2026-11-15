import 'package:smartbudget/features/calculator/domain/calculator_engine.dart';

/// The calculator's everyday tools, worked on the number shown: tax added or
/// taken out, a discount, a selling price from a cost, a bill split. Exact
/// (fixed-point, like the calculator); rates are per cent ("19" = 19%).
abstract final class CalcTools {
  static final CalcNumber _hundred = CalcNumber.parse('100')!;
  static final CalcNumber _one = CalcNumber.parse('1')!;

  static CalcNumber _share(CalcNumber rate) => rate.divide(_hundred)!;

  /// [amount] before tax → (tax, price with tax).
  static (CalcNumber tax, CalcNumber total) addTax(
      CalcNumber amount, CalcNumber rate) {
    final CalcNumber tax = amount * _share(rate);
    return (tax, amount + tax);
  }

  /// [amount] with tax included → (price before tax, tax inside). Null when
  /// the rate is −100% or less.
  static (CalcNumber net, CalcNumber tax)? extractTax(
      CalcNumber amount, CalcNumber rate) {
    final CalcNumber? net = amount.divide(_one + _share(rate));
    if (net == null || (_one + _share(rate)).isNegative) return null;
    return (net, amount - net);
  }

  /// [amount] with [rate] off → (saved, price after).
  static (CalcNumber saved, CalcNumber after) discount(
      CalcNumber amount, CalcNumber rate) {
    final CalcNumber saved = amount * _share(rate);
    return (saved, amount - saved);
  }

  /// A [cost] marked up by [rate] (profit as a share of the cost) →
  /// (selling price, profit).
  static (CalcNumber price, CalcNumber profit) markup(
      CalcNumber cost, CalcNumber rate) {
    final CalcNumber profit = cost * _share(rate);
    return (cost + profit, profit);
  }

  /// The price that leaves [rate] of it as profit over [cost] (margin on the
  /// selling price) → (selling price, profit). Null at 100% or more.
  static (CalcNumber price, CalcNumber profit)? marginPrice(
      CalcNumber cost, CalcNumber rate) {
    final CalcNumber rest = _one - _share(rate);
    if (rest.isZero || rest.isNegative) return null;
    final CalcNumber price = cost.divide(rest)!;
    return (price, price - cost);
  }

  /// [amount] shared by [people] (at least 1) → each one's part.
  static CalcNumber? split(CalcNumber amount, int people) {
    if (people < 1) return null;
    return amount.divide(CalcNumber.parse('$people')!);
  }
}

extension CalcCurrent on CalcState {
  /// The number the tools work on: the result, the answer so far, or what is
  /// being typed. Null on an error.
  CalcNumber? get current {
    if (error != null) return null;
    final CalcNumber? preview = Calculator.preview(this);
    if (preview != null) return preview;
    if (entry != null && !result && pending == null) {
      return CalcNumber.parse(entry!);
    }
    return accumulator ?? CalcNumber.zero;
  }
}
