/// What the user tells the zakat engine that the rest of the app doesn't
/// know: the market (country), the school, the hawl start, metal prices for
/// zakat, and per-record notes (a goal kept outside the wallets, a piece of
/// jewellery that is worn, a loan unlikely to be repaid).
///
/// Every field is optional: a user who never opened the zakat screen gets
/// [ZakatSettings.empty], and the engine flags what is missing instead of
/// guessing. Kept on the device only (no new cloud sync), under its own key;
/// the older key (`sb_zakat_inputs`) is read once through [fromLegacy] and
/// never written or removed.
library;

import 'package:smartbudget/features/zakat/domain/engine/zakat_case.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_money.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';

class ZakatSettings {
  const ZakatSettings({
    this.country,
    this.school = ZakatSchool.maliki,
    this.hawlStart,
    this.hawlAdjustDays = 0,
    this.goldPerPureGramMinor,
    this.silverPerPureGramMinor,
    this.priceCurrency,
    this.pricesAsOf,
    this.goalsHeldOutside = const <String>{},
    this.metalUses = const <String, MetalUse>{},
    this.doubtfulReceivables = const <String>{},
    this.manual = const <ZakatManual>[],
    this.investments = const <ZakatInvestment>[],
    this.legacyStandard,
    this.fromLegacy = false,
  });

  static const ZakatSettings empty = ZakatSettings();

  /// Shape of the stored JSON; bump on a breaking change.
  static const int version = 2;

  /// ISO country code of the zakat market ("DZ"); null follows the base
  /// currency (see ZakatMarket.resolve).
  final String? country;

  /// The school the rules follow. Maliki is the approved default for
  /// Algeria; the others are kept for a later choice.
  final ZakatSchool school;

  final DateTime? hawlStart;

  /// -1, 0 or +1 day, when the local moon sighting differs from the
  /// tabular calendar.
  final int hawlAdjustDays;

  /// Price of a gram of PURE gold / silver the user entered for zakat, in
  /// minor units of [priceCurrency]. Null: use the app's metal prices.
  final int? goldPerPureGramMinor;
  final int? silverPerPureGramMinor;
  final String? priceCurrency;
  final DateTime? pricesAsOf;

  /// Goal ids whose saved money is kept outside the app's wallets. Any other
  /// goal is taken as money already inside a wallet balance (never counted
  /// twice).
  final Set<String> goalsHeldOutside;

  /// Metal holding id → how it is used. Missing: unspecified (counted, and
  /// the result flagged as provisional).
  final Map<String, MetalUse> metalUses;

  /// Debt ids (money lent) the user doesn't expect to get back.
  final Set<String> doubtfulReceivables;

  /// Wealth the app doesn't track, entered for zakat.
  final List<ZakatManual> manual;
  final List<ZakatInvestment> investments;

  /// The nisab standard chosen in the older screen ("gold" / "silver").
  /// Kept for reference only: the Algerian rules use the official nisab.
  final String? legacyStandard;

  /// True when these settings were read from the older key and not yet
  /// saved under the new one.
  final bool fromLegacy;

  ZakatSettings copyWith({
    String? country,
    ZakatSchool? school,
    DateTime? hawlStart,
    bool clearHawlStart = false,
    int? hawlAdjustDays,
    int? goldPerPureGramMinor,
    int? silverPerPureGramMinor,
    String? priceCurrency,
    DateTime? pricesAsOf,
    Set<String>? goalsHeldOutside,
    Map<String, MetalUse>? metalUses,
    Set<String>? doubtfulReceivables,
    List<ZakatManual>? manual,
    List<ZakatInvestment>? investments,
  }) =>
      ZakatSettings(
        country: country ?? this.country,
        school: school ?? this.school,
        hawlStart: clearHawlStart ? null : (hawlStart ?? this.hawlStart),
        hawlAdjustDays: hawlAdjustDays ?? this.hawlAdjustDays,
        goldPerPureGramMinor: goldPerPureGramMinor ?? this.goldPerPureGramMinor,
        silverPerPureGramMinor:
            silverPerPureGramMinor ?? this.silverPerPureGramMinor,
        priceCurrency: priceCurrency ?? this.priceCurrency,
        pricesAsOf: pricesAsOf ?? this.pricesAsOf,
        goalsHeldOutside: goalsHeldOutside ?? this.goalsHeldOutside,
        metalUses: metalUses ?? this.metalUses,
        doubtfulReceivables: doubtfulReceivables ?? this.doubtfulReceivables,
        manual: manual ?? this.manual,
        investments: investments ?? this.investments,
        legacyStandard: legacyStandard,
        // Anything changed is saved under the new key.
        fromLegacy: false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': version,
        if (country != null) 'country': country,
        'school': school.name,
        if (hawlStart != null) 'hawlStart': _day(hawlStart!),
        if (hawlAdjustDays != 0) 'hawlAdjustDays': hawlAdjustDays,
        if (goldPerPureGramMinor != null) 'goldMinor': goldPerPureGramMinor,
        if (silverPerPureGramMinor != null) 'silverMinor': silverPerPureGramMinor,
        if (priceCurrency != null) 'priceCurrency': priceCurrency,
        if (pricesAsOf != null) 'pricesAsOf': pricesAsOf!.toIso8601String(),
        if (goalsHeldOutside.isNotEmpty)
          'goalsOutside': (goalsHeldOutside.toList()..sort()),
        if (metalUses.isNotEmpty)
          'metalUses': <String, String>{
            for (final MapEntry<String, MetalUse> e in metalUses.entries)
              e.key: e.value.name,
          },
        if (doubtfulReceivables.isNotEmpty)
          'doubtful': (doubtfulReceivables.toList()..sort()),
        if (manual.isNotEmpty)
          'manual': <Map<String, dynamic>>[
            for (final ZakatManual m in manual)
              <String, dynamic>{
                'key': m.key,
                'kind': m.kind.name,
                'currency': m.currency,
                'minor': m.amountMinor,
              },
          ],
        if (investments.isNotEmpty)
          'investments': <Map<String, dynamic>>[
            for (final ZakatInvestment i in investments)
              <String, dynamic>{
                'key': i.key,
                'kind': i.kind.name,
                'currency': i.currency,
                'minor': i.marketValueMinor,
                if (i.zakatablePartMinor != null) 'partMinor': i.zakatablePartMinor,
              },
          ],
        if (legacyStandard != null) 'legacyStandard': legacyStandard,
      };

  /// Never throws: anything unreadable falls back to "not set".
  factory ZakatSettings.fromJson(Map<String, dynamic> j) {
    final DateTime? start = DateTime.tryParse('${j['hawlStart'] ?? ''}');
    final int adjust = _int(j['hawlAdjustDays']) ?? 0;
    return ZakatSettings(
      country: _code(j['country']),
      school: _enum(ZakatSchool.values, j['school']) ?? ZakatSchool.maliki,
      hawlStart: start == null ? null : DateTime(start.year, start.month, start.day),
      hawlAdjustDays: adjust.clamp(-1, 1),
      goldPerPureGramMinor: _positive(j['goldMinor']),
      silverPerPureGramMinor: _positive(j['silverMinor']),
      priceCurrency: _code(j['priceCurrency']),
      pricesAsOf: DateTime.tryParse('${j['pricesAsOf'] ?? ''}'),
      goalsHeldOutside: _strings(j['goalsOutside']),
      metalUses: <String, MetalUse>{
        if (j['metalUses'] is Map)
          for (final MapEntry<dynamic, dynamic> e
              in (j['metalUses'] as Map<dynamic, dynamic>).entries)
            if (_enum(MetalUse.values, e.value) != null)
              '${e.key}': _enum(MetalUse.values, e.value)!,
      },
      doubtfulReceivables: _strings(j['doubtful']),
      manual: <ZakatManual>[
        for (final Map<String, dynamic> m in _maps(j['manual']))
          if (_manual(m) != null) _manual(m)!,
      ],
      investments: <ZakatInvestment>[
        for (final Map<String, dynamic> m in _maps(j['investments']))
          if (_investment(m) != null) _investment(m)!,
      ],
      legacyStandard: j['legacyStandard'] is String
          ? j['legacyStandard'] as String
          : null,
    );
  }

  /// The older screen's inputs (`sb_zakat_inputs`): gram prices, the nisab
  /// standard, the hawl start and three amounts typed by hand, all in what
  /// was then the base currency ([currency]). Read only; the old key is left
  /// as it is.
  factory ZakatSettings.fromLegacy(Map<String, dynamic> m, String currency) {
    int? minor(Object? v) {
      if (v is! num || !v.isFinite || v <= 0) return null;
      return _toMinor(v.toDouble(), currency);
    }

    final int? gold = minor(m['gold']);
    final int? silver = minor(m['silver']);
    final int? cash = minor(m['cash']);
    final int? metals = minor(m['metals']);
    final int? investments = minor(m['investments']);
    final DateTime? start = DateTime.tryParse('${m['hawlStart'] ?? ''}');
    return ZakatSettings(
      hawlStart: start == null ? null : DateTime(start.year, start.month, start.day),
      goldPerPureGramMinor: gold,
      silverPerPureGramMinor: silver,
      priceCurrency: gold != null || silver != null ? currency : null,
      manual: <ZakatManual>[
        if (cash != null)
          ZakatManual(
              key: 'legacy:cash',
              kind: ManualKind.cash,
              currency: currency,
              amountMinor: cash),
        if (metals != null)
          ZakatManual(
              key: 'legacy:metals',
              kind: ManualKind.metal,
              currency: currency,
              amountMinor: metals),
      ],
      investments: <ZakatInvestment>[
        if (investments != null)
          ZakatInvestment(
              key: 'legacy:investments',
              kind: InvestmentKind.unspecified,
              currency: currency,
              marketValueMinor: investments),
      ],
      legacyStandard: m['standard'] == 'silver' ? 'silver' : 'gold',
      fromLegacy: true,
    );
  }

  /// [amount] (major units, as the older screen kept it) in minor units:
  /// the currency's own decimals (2 when unknown).
  static int _toMinor(double amount, String currency) {
    final int decimals = ZakatMoney.decimalsOf(currency) ?? 2;
    double f = 1;
    for (int i = 0; i < decimals; i++) {
      f *= 10;
    }
    return (amount * f).round();
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

T? _enum<T extends Enum>(List<T> values, Object? name) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return null;
}

int? _int(Object? v) => v is num && v.isFinite ? v.toInt() : null;

int? _positive(Object? v) {
  final int? i = _int(v);
  return i != null && i > 0 ? i : null;
}

String? _code(Object? v) =>
    v is String && RegExp(r'^[A-Z]{2,3}$').hasMatch(v) ? v : null;

Set<String> _strings(Object? v) => v is List
    ? <String>{for (final Object? e in v) if (e is String && e.isNotEmpty) e}
    : const <String>{};

List<Map<String, dynamic>> _maps(Object? v) => v is List
    ? <Map<String, dynamic>>[
        for (final Object? e in v)
          if (e is Map) e.cast<String, dynamic>(),
      ]
    : const <Map<String, dynamic>>[];

ZakatManual? _manual(Map<String, dynamic> m) {
  final ManualKind? kind = _enum(ManualKind.values, m['kind']);
  final String? cur = _code(m['currency']);
  final int? minor = _positive(m['minor']);
  final Object? key = m['key'];
  if (kind == null || cur == null || minor == null || key is! String) {
    return null;
  }
  return ZakatManual(key: key, kind: kind, currency: cur, amountMinor: minor);
}

ZakatInvestment? _investment(Map<String, dynamic> m) {
  final InvestmentKind? kind = _enum(InvestmentKind.values, m['kind']);
  final String? cur = _code(m['currency']);
  final int? minor = _positive(m['minor']);
  final Object? key = m['key'];
  if (kind == null || cur == null || minor == null || key is! String) {
    return null;
  }
  return ZakatInvestment(
      key: key,
      kind: kind,
      currency: cur,
      marketValueMinor: minor,
      zakatablePartMinor: _int(m['partMinor']));
}
