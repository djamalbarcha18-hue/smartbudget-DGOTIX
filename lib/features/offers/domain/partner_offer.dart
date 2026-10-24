import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/domain/trip.dart';
import 'package:smartbudget/features/trips/domain/trip_item.dart';
import 'package:smartbudget/features/trips/domain/trip_report.dart';

/// What a partner offers.
enum OfferKind {
  esim,
  hotel,
  airline,
  transport,
  restaurant,
  insurance,
  agency,
  activity,
}

/// Where an offer may show: one place per screen, at the moment it helps.
enum OfferSlot {
  /// In the trip editor, by the hotel / airline / agency the user types.
  tripEditor,

  /// On the trip's home card in the two weeks before it.
  beforeTrip,

  /// On the trip's home card while it is under way.
  duringTrip,
}

/// A partner's offer (from assets/data/partner_offers.json, later the
/// server): shown, never sent anything about the user.
class PartnerOffer {
  const PartnerOffer({
    required this.id,
    required this.partner,
    required this.kind,
    required this.title,
    required this.body,
    required this.url,
    this.destinations = const <String>{},
    this.countries = const <String>{},
    this.from,
    this.until,
  });

  final String id;
  final String partner;
  final OfferKind kind;

  /// By language code ('ar', 'en'…); English, then any, when missing.
  final Map<String, String> title;
  final Map<String, String> body;
  final String url;

  /// Catalog place ids and country codes it is for; both empty: anywhere.
  final Set<String> destinations;
  final Set<String> countries;
  final DateTime? from;
  final DateTime? until;

  static String text(Map<String, String> m, String lang) =>
      m[lang] ?? m['en'] ?? (m.isEmpty ? '' : m.values.first);

  /// The link with SmartBudget as its source (for the partner's commission).
  Uri link() {
    final Uri u = Uri.parse(url);
    return u.replace(queryParameters: <String, String>{
      ...u.queryParameters,
      'utm_source': 'smartbudget',
      'utm_medium': 'app',
      'utm_campaign': 'smarttrip',
    });
  }

  bool liveOn(DateTime day) =>
      (from == null || !day.isBefore(from!)) &&
      (until == null || !day.isAfter(until!));

  /// For a trip to [place] (null: a place typed by the user, matched only by
  /// offers meant for anywhere).
  bool isFor(Destination? place) {
    if (destinations.isEmpty && countries.isEmpty) return true;
    if (place == null) return false;
    return destinations.contains(place.id) || countries.contains(place.country);
  }

  static Map<String, String> _texts(Object? v) => v is Map
      ? <String, String>{
          for (final MapEntry<dynamic, dynamic> e in v.entries)
            '${e.key}': '${e.value}',
        }
      : const <String, String>{};

  /// Null for an offer it can't read (unknown kind, no link…).
  static PartnerOffer? fromJson(Map<String, dynamic> j) {
    final OfferKind? kind = OfferKind.values
        .where((OfferKind k) => k.name == j['kind'])
        .firstOrNull;
    final String? url = j['url'] as String?;
    final String? id = j['id'] as String?;
    if (kind == null || url == null || id == null) return null;
    final Uri? u = Uri.tryParse(url);
    if (u == null || u.scheme != 'https') return null;
    return PartnerOffer(
      id: id,
      partner: (j['partner'] as String?) ?? '',
      kind: kind,
      title: _texts(j['title']),
      body: _texts(j['body']),
      url: url,
      destinations: <String>{
        for (final dynamic d
            in (j['destinations'] as List<dynamic>?) ?? <dynamic>[])
          '$d',
      },
      countries: <String>{
        for (final dynamic c
            in (j['countries'] as List<dynamic>?) ?? <dynamic>[])
          '$c',
      },
      from: DateTime.tryParse((j['from'] as String?) ?? ''),
      until: DateTime.tryParse((j['until'] as String?) ?? ''),
    );
  }
}

/// Picks the one offer a slot shows, on the device, from the trip alone:
/// nothing when nothing fits, when it was hidden less than [hiddenFor] ago,
/// or after the trip.
abstract final class OfferMatcher {
  /// A hidden offer stays away this long.
  static const Duration hiddenFor = Duration(days: 30);

  /// "Before the trip" starts this many days ahead.
  static const int beforeDays = 14;

  static PartnerOffer? pick({
    required List<PartnerOffer> offers,
    required OfferSlot slot,
    required Trip trip,
    required Destination? place,
    required DateTime now,
    Map<String, DateTime> hidden = const <String, DateTime>{},
    TripReport? report,
  }) {
    final TripStatus status = TripMath.status(trip, now);
    final Set<TripItem> spentOn = <TripItem>{
      for (final TripItemShare s
          in report?.categories ?? const <TripItemShare>[])
        s.item,
    };
    // Which kinds, best first, for this slot and moment.
    final List<OfferKind> kinds = switch (slot) {
      OfferSlot.tripEditor => status == TripStatus.ended
          ? const <OfferKind>[]
          : trip.kind == TripKind.organized
              ? const <OfferKind>[OfferKind.agency, OfferKind.hotel]
              : const <OfferKind>[OfferKind.hotel, OfferKind.airline],
      OfferSlot.beforeTrip => status == TripStatus.upcoming &&
              TripMath.daysUntil(trip, now) <= beforeDays
          ? <OfferKind>[
              // What isn't arranged yet.
              if (!spentOn.contains(TripItem.connectivity)) OfferKind.esim,
              if (!spentOn.contains(TripItem.emergency)) OfferKind.insurance,
              OfferKind.transport,
            ]
          : const <OfferKind>[],
      OfferSlot.duringTrip => status == TripStatus.active
          ? <OfferKind>[
              if (!spentOn.contains(TripItem.connectivity)) OfferKind.esim,
              OfferKind.transport,
              OfferKind.restaurant,
              OfferKind.activity,
            ]
          : const <OfferKind>[],
    };
    final DateTime day = DateTime(now.year, now.month, now.day);
    for (final OfferKind k in kinds) {
      final List<PartnerOffer> fit = <PartnerOffer>[
        for (final PartnerOffer o in offers)
          if (o.kind == k &&
              o.liveOn(day) &&
              o.isFor(place) &&
              !_stillHidden(hidden[o.id], now))
            o,
      ];
      if (fit.isEmpty) continue;
      // Several partners: take turns by day, so each gets seen.
      return fit[day.difference(DateTime(2026)).inDays.abs() % fit.length];
    }
    return null;
  }

  static bool _stillHidden(DateTime? at, DateTime now) =>
      at != null && now.difference(at) < hiddenFor;
}
