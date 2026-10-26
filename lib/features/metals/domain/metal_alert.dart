import 'package:smartbudget/features/metals/domain/metal_holding.dart';
import 'package:smartbudget/features/metals/domain/metals_valuation.dart';

/// "Tell me when a gram of pure [metal] reaches [target] [currency]": when
/// it rises to it ([above]) or falls to it.
class MetalAlert {
  const MetalAlert({
    required this.metal,
    required this.target,
    required this.currency,
    required this.above,
  });

  final Metal metal;
  final double target;
  final String currency;
  final bool above;

  /// Whether [price] meets the alert. A price in another currency never does.
  bool metBy(MetalPrice price) =>
      price.currency == currency &&
      (above ? price.perGram >= target : price.perGram <= target);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'metal': metal.name,
        'target': target,
        'currency': currency,
        'above': above,
      };

  static MetalAlert? fromJson(Object? j) {
    if (j is! Map) return null;
    final Metal? m = MetalX.byName('${j['metal']}');
    final Object? t = j['target'];
    final Object? c = j['currency'];
    if (m == null || t is! num || t <= 0 || c is! String || c.isEmpty) {
      return null;
    }
    return MetalAlert(
        metal: m,
        target: t.toDouble(),
        currency: c,
        above: j['above'] != false);
  }
}
