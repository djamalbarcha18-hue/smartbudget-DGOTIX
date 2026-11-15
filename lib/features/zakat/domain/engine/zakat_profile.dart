/// What a country adds to the zakat engine: its currency, its official nisab
/// announcements and its default rules. The engine itself holds no country
/// values; one profile is enabled today (Algeria).
library;

import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';

/// A nisab amount an official body announced, with what it was computed
/// from. Each announcement belongs to one Hijri year: it is never assumed to
/// hold for later years.
class OfficialNisab {
  const OfficialNisab({
    required this.hijriYear,
    required this.amountMinor,
    required this.currency,
    required this.grams,
    required this.goldKarat,
    required this.gramPriceMinor,
    required this.source,
    required this.sourceUrl,
    this.announcedOn,
  });

  /// The Hijri year the announcement is for (1447).
  final int hijriYear;

  /// The announced amount, in minor units of [currency].
  final int amountMinor;
  final String currency;

  /// What it equals: [grams] of gold of [goldKarat] karat at [gramPriceMinor]
  /// per gram of that karat.
  final int grams;
  final int goldKarat;
  final int gramPriceMinor;

  final String source;
  final String sourceUrl;

  /// When it was announced; null when the source didn't give the date.
  final DateTime? announcedOn;
}

class ZakatProfile {
  const ZakatProfile({
    required this.code,
    required this.currency,
    required this.officialNisab,
    required this.defaultRules,
  });

  /// ISO 3166-1 alpha-2 ("DZ").
  final String code;

  /// The currency zakat is computed in.
  final String currency;

  /// Announcements, any order.
  final List<OfficialNisab> officialNisab;

  /// The rules a new user starts with (see ZakatRules.approved).
  final ZakatRules defaultRules;

  /// The announcement to use on [date]: the newest one announced on or
  /// before it (one without a date counts by its Hijri year). Null when
  /// there is none.
  OfficialNisab? officialFor(DateTime date) {
    OfficialNisab? best;
    for (final OfficialNisab n in officialNisab) {
      final DateTime? on = n.announcedOn;
      if (on != null && on.isAfter(date)) continue;
      if (best == null || n.hijriYear > best.hijriYear) best = n;
    }
    return best;
  }
}
