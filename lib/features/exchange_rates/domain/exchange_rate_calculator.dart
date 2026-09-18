/// Currency conversion via a USD reference, matching SmartBudget V1 where each
/// rate is "units of the currency per 1 USD" (USD == 1.0).
///
/// convert(amount, from, to) = amount / rate[from] * rate[to].
/// Pure and unit-tested; no network. Live rates arrive with the backend phase.
abstract final class ExchangeRateCalculator {
  static double convert({
    required double amount,
    required String from,
    required String to,
    required Map<String, double> ratesVsUsd,
  }) {
    if (from == to) return amount;
    final double rFrom = ratesVsUsd[from] ?? 0;
    final double rTo = ratesVsUsd[to] ?? 0;
    if (rFrom <= 0 || rTo <= 0) return 0;
    final double usd = amount / rFrom;
    return usd * rTo;
  }
}
