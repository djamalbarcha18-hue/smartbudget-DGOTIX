/// Top-level market categories shown as tabs inside the Markets section.
///
/// Adding a new category (e.g. carbon credits, fertilizers) is a matter of
/// adding an enum value, a config list, and registering a data provider — the
/// market engine and UI iterate over this enum, so nothing else is rewritten.
enum MarketCategory {
  exchangeRates,
  crypto,
  preciousMetals,
  industrialMetals,
  steelIron,
  energy,
  agriculture,
}
