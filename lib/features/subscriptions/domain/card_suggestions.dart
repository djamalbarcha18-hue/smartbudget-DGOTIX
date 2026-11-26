/// Suggestions for the optional card name of a subscription: the cards and
/// accounts people in the user's country commonly pay subscriptions with,
/// then those used everywhere. Suggestions only: the user can type any name
/// (CardName.clean still applies).
///
/// Only names known for sure are listed; a country missing here simply gets
/// the global list. Add a country when its cards are confirmed.
abstract final class CardSuggestions {
  /// Used all over the world.
  static const List<String> global = <String>[
    'Visa',
    'Mastercard',
    'PayPal',
    'American Express',
    'Google Pay',
    'Apple Pay',
    'Payoneer',
    'Wise',
    'Revolut',
    'RedotPay',
  ];

  /// By ISO 3166-1 alpha-2 country code (upper case), first in the list.
  static const Map<String, List<String>> byCountry = <String, List<String>>{
    // Algeria (owner's request): Algérie Poste's card, the interbank card,
    // then the accounts most used for foreign subscriptions.
    'DZ': <String>[
      'الذهبية (Edahabia)',
      'CIB',
      'RedotPay',
      'PayPal',
      'Payoneer',
    ],
    'TN': <String>['e-Dinar'],
    'EG': <String>['Meeza'],
    'SA': <String>['mada'],
    'TR': <String>['Troy'],
    'IN': <String>['RuPay'],
    'CN': <String>['UnionPay'],
    'JP': <String>['JCB'],
    'FR': <String>['Carte Bancaire (CB)'],
    'BR': <String>['Elo'],
    'NG': <String>['Verve'],
    'RU': <String>['Mir'],
    'PK': <String>['PayPak'],
  };

  /// Suggestions for [country] (any case; null or unknown = global only):
  /// the country's own first, then the global ones, each name once.
  static List<String> forCountry(String? country) {
    final List<String> local =
        byCountry[(country ?? '').trim().toUpperCase()] ?? const <String>[];
    final Set<String> seen = <String>{};
    return <String>[
      for (final String n in <String>[...local, ...global])
        if (seen.add(n.toLowerCase())) n,
    ];
  }

  /// [forCountry] narrowed to the names containing [query] (case ignored),
  /// for the field's autocomplete. An empty query returns them all.
  static List<String> matching(String? country, String query) {
    final String q = query.trim().toLowerCase();
    final List<String> all = forCountry(country);
    if (q.isEmpty) return all;
    return all.where((String n) => n.toLowerCase().contains(q)).toList();
  }
}
