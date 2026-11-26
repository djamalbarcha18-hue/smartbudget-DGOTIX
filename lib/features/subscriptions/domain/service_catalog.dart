import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/subscriptions/domain/subscription.dart';

/// How the catalog groups services in the picker.
enum ServiceGroup { video, music, ai, cloudWork, games, mobile, homeInternet }

/// One service the add form offers ready-made. No prices: the user enters
/// what they pay (it differs by plan, country and currency, and changes).
class CatalogService {
  const CatalogService({
    required this.id,
    required this.name,
    required this.group,
    this.frequency = RecurrenceFrequency.monthly,
    this.country,
    this.manageUrl,
  });

  /// Stable key, stored as Subscription.catalogId.
  final String id;

  /// The brand's own name (never translated).
  final String name;
  final ServiceGroup group;

  /// The usual cycle, preselected in the form.
  final RecurrenceFrequency frequency;

  /// ISO country for a local carrier or provider; null = everywhere.
  final String? country;

  /// The provider's official page to manage or cancel. Null until checked by
  /// hand: then the app shows the general cancelling steps instead.
  final String? manageUrl;

  SubscriptionKind get kind =>
      group == ServiceGroup.mobile || group == ServiceGroup.homeInternet
          ? SubscriptionKind.mobile
          : SubscriptionKind.digital;
}

/// The built-in list (owner's choice, 2026-11-26). Shipped in the app: no
/// server, nothing fetched, no logos (an initial and a colour instead).
/// Anything missing is added with "Other subscription".
abstract final class ServiceCatalog {
  static const List<CatalogService> all = <CatalogService>[
    // Video
    CatalogService(id: 'netflix', name: 'Netflix', group: ServiceGroup.video),
    CatalogService(
        id: 'youtube_premium',
        name: 'YouTube Premium',
        group: ServiceGroup.video),
    CatalogService(
        id: 'shahid_vip', name: 'Shahid VIP', group: ServiceGroup.video),
    CatalogService(
        id: 'prime_video',
        name: 'Amazon Prime Video',
        group: ServiceGroup.video),
    CatalogService(
        id: 'disney_plus', name: 'Disney+', group: ServiceGroup.video),
    CatalogService(id: 'osn_plus', name: 'OSN+', group: ServiceGroup.video),
    // Music
    CatalogService(id: 'spotify', name: 'Spotify', group: ServiceGroup.music),
    CatalogService(id: 'anghami', name: 'Anghami', group: ServiceGroup.music),
    CatalogService(id: 'deezer', name: 'Deezer', group: ServiceGroup.music),
    CatalogService(
        id: 'apple_music', name: 'Apple Music', group: ServiceGroup.music),
    // AI
    CatalogService(
        id: 'chatgpt_plus', name: 'ChatGPT Plus', group: ServiceGroup.ai),
    CatalogService(id: 'claude_pro', name: 'Claude Pro', group: ServiceGroup.ai),
    CatalogService(
        id: 'google_one',
        name: 'Google One (Gemini)',
        group: ServiceGroup.ai),
    // Storage and work
    CatalogService(
        id: 'icloud_plus', name: 'iCloud+', group: ServiceGroup.cloudWork),
    CatalogService(
        id: 'microsoft_365',
        name: 'Microsoft 365',
        group: ServiceGroup.cloudWork),
    CatalogService(
        id: 'canva_pro', name: 'Canva Pro', group: ServiceGroup.cloudWork),
    CatalogService(id: 'adobe', name: 'Adobe', group: ServiceGroup.cloudWork),
    // Games and more
    CatalogService(
        id: 'xbox_game_pass',
        name: 'Xbox Game Pass',
        group: ServiceGroup.games),
    CatalogService(
        id: 'playstation_plus',
        name: 'PlayStation Plus',
        group: ServiceGroup.games),
    CatalogService(
        id: 'telegram_premium',
        name: 'Telegram Premium',
        group: ServiceGroup.games),
    CatalogService(id: 'duolingo', name: 'Duolingo', group: ServiceGroup.games),
    // Phone plans, Algeria
    CatalogService(
        id: 'dz_djezzy',
        name: 'Djezzy',
        group: ServiceGroup.mobile,
        country: 'DZ'),
    CatalogService(
        id: 'dz_mobilis',
        name: 'Mobilis',
        group: ServiceGroup.mobile,
        country: 'DZ'),
    CatalogService(
        id: 'dz_ooredoo',
        name: 'Ooredoo',
        group: ServiceGroup.mobile,
        country: 'DZ'),
    // Home internet, Algeria
    CatalogService(
        id: 'dz_idoom',
        name: 'Algérie Télécom (Idoom)',
        group: ServiceGroup.homeInternet,
        country: 'DZ'),
  ];

  static CatalogService? byId(String? id) {
    if (id == null) return null;
    for (final CatalogService s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// What the picker shows for someone in [country]: services available
  /// everywhere plus that country's own, local carriers and providers first.
  /// Another country's carriers are left out (the user can still type one).
  static List<CatalogService> forCountry(String? country) {
    final String c = (country ?? '').trim().toUpperCase();
    final List<CatalogService> local = <CatalogService>[
      for (final CatalogService s in all)
        if (s.country != null && s.country == c) s,
    ];
    return <CatalogService>[
      ...local,
      for (final CatalogService s in all)
        if (s.country == null) s,
    ];
  }

  /// [forCountry] narrowed to names containing [query] (case ignored).
  static List<CatalogService> search(String? country, String query) {
    final String q = query.trim().toLowerCase();
    final List<CatalogService> list = forCountry(country);
    if (q.isEmpty) return list;
    return list
        .where((CatalogService s) => s.name.toLowerCase().contains(q))
        .toList();
  }
}
