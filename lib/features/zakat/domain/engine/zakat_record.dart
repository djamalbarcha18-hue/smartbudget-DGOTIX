/// A zakat calculation the user confirmed («اعتمد الحساب»), kept as it was:
/// the date, the rules and their version, every line, the rates and prices,
/// the nisab and the amount. Later changes to the rules, prices or the
/// user's data never change a saved record; the history only grows.
library;

import 'package:smartbudget/features/zakat/domain/engine/zakat_case.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_engine.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_money.dart';

class ZakatRecordLine {
  const ZakatRecordLine({
    required this.key,
    required this.section,
    required this.currency,
    required this.originalMinor,
    required this.valueMinor,
    required this.counted,
    required this.note,
  });

  final String key;
  final String section;
  final String currency;
  final int originalMinor;
  final int valueMinor;
  final bool counted;
  final String note;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'section': section,
        'currency': currency,
        'original': originalMinor,
        'value': valueMinor,
        'counted': counted,
        'note': note,
      };

  static ZakatRecordLine? fromJson(Object? v) {
    if (v is! Map) return null;
    final Map<String, dynamic> j = v.cast<String, dynamic>();
    final Object? o = j['original'];
    final Object? val = j['value'];
    if (j['key'] is! String || o is! num || val is! num) return null;
    return ZakatRecordLine(
      key: j['key'] as String,
      section: '${j['section'] ?? ''}',
      currency: '${j['currency'] ?? ''}',
      originalMinor: o.toInt(),
      valueMinor: val.toInt(),
      counted: j['counted'] == true,
      note: '${j['note'] ?? ''}',
    );
  }
}

class ZakatRecord {
  const ZakatRecord({
    required this.id,
    required this.savedAt,
    required this.zakatDate,
    required this.country,
    required this.currency,
    required this.status,
    required this.rules,
    required this.nisab,
    required this.nisabMet,
    required this.obligatoryNow,
    required this.assetsMinor,
    required this.deductionsMinor,
    required this.baseMinor,
    required this.dueMinor,
    required this.lines,
    this.hawlStart,
    this.hawlEnd,
    this.fx = const <Map<String, dynamic>>[],
    this.prices = const <String, Map<String, dynamic>>{},
    this.issues = const <String>[],
    this.note,
  });

  static const int version = 1;

  final String id;
  final DateTime savedAt;
  final DateTime zakatDate;

  /// The market profile ("DZ").
  final String country;
  final String currency;

  /// "provisional" or "final_" (an incomplete calculation is never saved).
  final String status;

  /// The rules as they were ([ZakatRules.toJson]), version included.
  final Map<String, dynamic> rules;

  /// The nisab used: basis, amount, source, Hijri year, grams, karat.
  final Map<String, dynamic> nisab;
  final bool nisabMet;
  final bool obligatoryNow;
  final int assetsMinor;
  final int deductionsMinor;
  final int baseMinor;
  final int dueMinor;
  final List<ZakatRecordLine> lines;
  final DateTime? hawlStart;
  final DateTime? hawlEnd;

  /// Exchange rates used ([FxQuote.toJson]).
  final List<Map<String, dynamic>> fx;

  /// "gold" / "silver" → price per pure gram, date and source.
  final Map<String, Map<String, dynamic>> prices;

  /// Codes of the cautions shown with the result.
  final List<String> issues;
  final String? note;

  String get rulesVersion => '${rules['version'] ?? ''}';

  /// The record of [o] (computed from [c]); null when [o] has no amount
  /// (incomplete): such a result can't be confirmed.
  static ZakatRecord? fromOutcome(
    ZakatOutcome o,
    ZakatCase c, {
    required String id,
    required DateTime savedAt,
    String? note,
  }) {
    if (o.status == ZakatStatus.incomplete) return null;
    final ZakatNisab? n = o.nisab;
    if (n == null) return null;
    Map<String, dynamic>? price(MetalPriceQuote? q) => q == null
        ? null
        : <String, dynamic>{
            'perPureGramMinor': q.perPureGramMinor,
            'asOf': q.asOf.toIso8601String(),
            'source': q.source,
          };
    final Map<String, dynamic>? gold = price(c.goldPrice);
    final Map<String, dynamic>? silver = price(c.silverPrice);
    return ZakatRecord(
      id: id,
      savedAt: savedAt,
      zakatDate: o.zakatDate,
      country: c.profile.code,
      currency: o.currency,
      status: o.status.name,
      rules: o.rules.toJson(),
      nisab: <String, dynamic>{
        'basis': n.basis.name,
        'amountMinor': n.amountMinor,
        'source': n.source,
        if (n.asOf != null) 'asOf': n.asOf!.toIso8601String(),
        if (n.hijriYear != null) 'hijriYear': n.hijriYear,
        if (n.grams != null) 'grams': n.grams,
        if (n.karat != null) 'karat': n.karat,
        if (n.gramPriceMinor != null) 'gramPriceMinor': n.gramPriceMinor,
      },
      nisabMet: o.nisabMet,
      obligatoryNow: o.obligatoryNow,
      assetsMinor: o.assetsMinor,
      deductionsMinor: o.deductionsMinor,
      baseMinor: o.baseMinor,
      dueMinor: o.dueMinor,
      lines: <ZakatRecordLine>[
        for (final ZakatLine l in o.lines)
          ZakatRecordLine(
              key: l.key,
              section: l.section.name,
              currency: l.currency,
              originalMinor: l.originalMinor,
              valueMinor: l.valueMinor,
              counted: l.counted,
              note: l.note.name),
      ],
      hawlStart: o.hawl?.start,
      hawlEnd: o.hawl?.end,
      fx: <Map<String, dynamic>>[for (final FxQuote q in o.fxUsed) q.toJson()],
      prices: <String, Map<String, dynamic>>{
        if (gold != null) 'gold': gold,
        if (silver != null) 'silver': silver,
      },
      issues: <String>[for (final ZakatIssue i in o.issues) i.code.name],
      note: note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': version,
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'zakatDate': zakatDate.toIso8601String(),
        'country': country,
        'currency': currency,
        'status': status,
        'rules': rules,
        'nisab': nisab,
        'nisabMet': nisabMet,
        'obligatoryNow': obligatoryNow,
        'assets': assetsMinor,
        'deductions': deductionsMinor,
        'base': baseMinor,
        'due': dueMinor,
        'lines': <Map<String, dynamic>>[
          for (final ZakatRecordLine l in lines) l.toJson(),
        ],
        if (hawlStart != null) 'hawlStart': hawlStart!.toIso8601String(),
        if (hawlEnd != null) 'hawlEnd': hawlEnd!.toIso8601String(),
        if (fx.isNotEmpty) 'fx': fx,
        if (prices.isNotEmpty) 'prices': prices,
        if (issues.isNotEmpty) 'issues': issues,
        if (note != null) 'note': note,
      };

  /// Null when [v] isn't a readable record (the raw entry is still kept by
  /// the history, see ZakatHistory).
  static ZakatRecord? fromJson(Object? v) {
    if (v is! Map) return null;
    try {
      final Map<String, dynamic> j = v.cast<String, dynamic>();
      final DateTime? saved = DateTime.tryParse('${j['savedAt']}');
      final DateTime? date = DateTime.tryParse('${j['zakatDate']}');
      final Object? id = j['id'];
      if (id is! String || id.isEmpty || saved == null || date == null) {
        return null;
      }
      int n(Object? x) => x is num ? x.toInt() : 0;
      Map<String, dynamic> map(Object? x) =>
          x is Map ? x.cast<String, dynamic>() : <String, dynamic>{};
      return ZakatRecord(
        id: id,
        savedAt: saved,
        zakatDate: date,
        country: '${j['country'] ?? ''}',
        currency: '${j['currency'] ?? ''}',
        status: '${j['status'] ?? ''}',
        rules: map(j['rules']),
        nisab: map(j['nisab']),
        nisabMet: j['nisabMet'] == true,
        obligatoryNow: j['obligatoryNow'] == true,
        assetsMinor: n(j['assets']),
        deductionsMinor: n(j['deductions']),
        baseMinor: n(j['base']),
        dueMinor: n(j['due']),
        lines: <ZakatRecordLine>[
          if (j['lines'] is List)
            for (final Object? l in j['lines'] as List<dynamic>)
              if (ZakatRecordLine.fromJson(l) != null)
                ZakatRecordLine.fromJson(l)!,
        ],
        hawlStart: DateTime.tryParse('${j['hawlStart'] ?? ''}'),
        hawlEnd: DateTime.tryParse('${j['hawlEnd'] ?? ''}'),
        fx: <Map<String, dynamic>>[
          if (j['fx'] is List)
            for (final Object? q in j['fx'] as List<dynamic>)
              if (q is Map) q.cast<String, dynamic>(),
        ],
        prices: <String, Map<String, dynamic>>{
          for (final MapEntry<String, dynamic> e in map(j['prices']).entries)
            if (e.value is Map)
              e.key: (e.value as Map<dynamic, dynamic>).cast<String, dynamic>(),
        },
        issues: <String>[
          if (j['issues'] is List)
            for (final Object? i in j['issues'] as List<dynamic>)
              if (i is String) i,
        ],
        note: j['note'] is String ? j['note'] as String : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The history as stored: raw JSON entries, so an entry this version can't
/// read (written by a newer app) is kept untouched instead of being dropped
/// on the next save. Append-only: an id is never replaced.
abstract final class ZakatHistory {
  static String? idOf(Object? raw) =>
      raw is Map && raw['id'] is String ? raw['id'] as String : null;

  /// [raw] with [r] added at the end; unchanged when its id is already
  /// there (a saved record is never overwritten).
  static List<Object?> append(List<Object?> raw, ZakatRecord r) {
    if (raw.any((Object? e) => idOf(e) == r.id)) return raw;
    return <Object?>[...raw, r.toJson()];
  }

  /// [local] with the entries of [incoming] whose id it doesn't hold yet
  /// (a restore never changes or removes a record already on the device).
  static List<Object?> merge(List<Object?> local, List<Object?> incoming) {
    final Set<String> have = <String>{
      for (final Object? e in local)
        if (idOf(e) != null) idOf(e)!,
    };
    final List<Object?> out = <Object?>[...local];
    for (final Object? e in incoming) {
      final String? id = idOf(e);
      if (id == null || have.contains(id)) continue;
      have.add(id);
      out.add(e);
    }
    return out;
  }

  /// The readable records, newest zakat date first.
  static List<ZakatRecord> read(List<Object?> raw) {
    final List<ZakatRecord> out = <ZakatRecord>[
      for (final Object? e in raw)
        if (ZakatRecord.fromJson(e) != null) ZakatRecord.fromJson(e)!,
    ];
    out.sort((ZakatRecord a, ZakatRecord b) {
      final int c = b.zakatDate.compareTo(a.zakatDate);
      return c != 0 ? c : b.savedAt.compareTo(a.savedAt);
    });
    return out;
  }
}
