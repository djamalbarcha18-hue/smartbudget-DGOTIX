/// The fiqh choices the zakat engine follows, kept out of the arithmetic.
///
/// Every choice here is one where scholars differ (or where the app needs a
/// decision), so none is hard-coded: a [ZakatRules] value names the option
/// taken for each, carries a version, and says whether the defaults were
/// approved. A saved calculation keeps the rules it used, so changing the
/// rules later never changes an earlier result.
library;

/// Which nisab the wealth is measured against.
enum NisabBasis {
  /// 85 g of pure (24 karat) gold at the gold price of the zakat date.
  gold,

  /// 595 g of pure silver at the silver price of the zakat date.
  silver,

  /// The amount a country's official body announced (see ZakatProfile).
  official,
}

/// Money that came in during the hawl (salary, gift, transfer in).
enum AcquiredWealthPolicy {
  /// Joined to the hawl of the wealth that reached nisab: everything held on
  /// the zakat date is zakatable (Hanafi; for the majority, paying it is an
  /// allowed early payment for the newer money).
  joinToHawl,

  /// Only what stayed the whole hawl is zakatable: the lowest cash balance
  /// during the hawl stands for it (an approximation of the majority view,
  /// where each new sum starts its own hawl).
  minimumBalance,
}

/// When the wealth drops below nisab during the hawl.
enum NisabContinuity {
  /// Only the start and the end of the hawl count (Hanafi).
  startAndEnd,

  /// It must stay at nisab throughout; a drop restarts the hawl (majority).
  throughout,
}

/// Gold or silver jewellery worn as permitted adornment.
enum WornJewelryPolicy {
  /// No zakat on it (majority, including the Maliki school).
  exempt,

  /// Zakat on it like any gold or silver (Hanafi and some contemporaries).
  zakatable,
}

/// Shares held for their returns rather than for resale.
enum RetainedSharesPolicy {
  /// The zakatable part the user entered (the company's zakatable assets per
  /// share, AAOIFI standard 35); the full market value when it is unknown,
  /// with a warning that this is the cautious upper bound.
  zakatablePartElseFullValue,

  /// Always the full market value.
  fullValue,
}

/// Which of the user's own debts reduce the zakatable wealth.
enum DebtDeductionPolicy {
  /// None.
  none,

  /// What is due on or before the zakat date (a debt with no due date counts
  /// as due now).
  dueByZakatDate,

  /// What falls due within twelve months of the zakat date.
  dueWithin12Months,

  /// Every outstanding debt.
  all,
}

/// Debts others owe the user that are expected to be repaid.
enum ReceivablesPolicy {
  /// Added every year (majority).
  yearly,

  /// Not added until received (Maliki: then zakat for one year).
  onReceipt,
}

/// How the 2.5% is rounded to the currency's smallest unit.
enum RoundingPolicy { halfUp, up, down }

class ZakatRules {
  const ZakatRules({
    required this.version,
    required this.approved,
    required this.nisabBasis,
    required this.acquiredWealth,
    required this.nisabContinuity,
    required this.wornJewelry,
    required this.retainedShares,
    required this.debtDeduction,
    required this.receivables,
    required this.rounding,
    this.rateBasisPoints = 250,
  });

  /// Identifies this set of rules in saved calculations ("dz-2026.11").
  final String version;

  /// False until the defaults were reviewed and approved: results computed
  /// under unapproved rules are never shown as final.
  final bool approved;

  final NisabBasis nisabBasis;
  final AcquiredWealthPolicy acquiredWealth;
  final NisabContinuity nisabContinuity;
  final WornJewelryPolicy wornJewelry;
  final RetainedSharesPolicy retainedShares;
  final DebtDeductionPolicy debtDeduction;
  final ReceivablesPolicy receivables;
  final RoundingPolicy rounding;

  /// 2.5% (a quarter of a tenth), in hundredths of a percent.
  final int rateBasisPoints;

  ZakatRules copyWith({
    String? version,
    bool? approved,
    NisabBasis? nisabBasis,
    AcquiredWealthPolicy? acquiredWealth,
    NisabContinuity? nisabContinuity,
    WornJewelryPolicy? wornJewelry,
    RetainedSharesPolicy? retainedShares,
    DebtDeductionPolicy? debtDeduction,
    ReceivablesPolicy? receivables,
    RoundingPolicy? rounding,
  }) =>
      ZakatRules(
        version: version ?? this.version,
        approved: approved ?? this.approved,
        nisabBasis: nisabBasis ?? this.nisabBasis,
        acquiredWealth: acquiredWealth ?? this.acquiredWealth,
        nisabContinuity: nisabContinuity ?? this.nisabContinuity,
        wornJewelry: wornJewelry ?? this.wornJewelry,
        retainedShares: retainedShares ?? this.retainedShares,
        debtDeduction: debtDeduction ?? this.debtDeduction,
        receivables: receivables ?? this.receivables,
        rounding: rounding ?? this.rounding,
        rateBasisPoints: rateBasisPoints,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'approved': approved,
        'nisabBasis': nisabBasis.name,
        'acquiredWealth': acquiredWealth.name,
        'nisabContinuity': nisabContinuity.name,
        'wornJewelry': wornJewelry.name,
        'retainedShares': retainedShares.name,
        'debtDeduction': debtDeduction.name,
        'receivables': receivables.name,
        'rounding': rounding.name,
        'rateBasisPoints': rateBasisPoints,
      };

  static T _pick<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final T v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  /// Reads saved rules; an unknown value keeps [fallback]'s.
  factory ZakatRules.fromJson(Map<String, dynamic> j, ZakatRules fallback) =>
      ZakatRules(
        version: (j['version'] as String?) ?? fallback.version,
        approved: (j['approved'] as bool?) ?? false,
        nisabBasis:
            _pick(NisabBasis.values, j['nisabBasis'], fallback.nisabBasis),
        acquiredWealth: _pick(AcquiredWealthPolicy.values, j['acquiredWealth'],
            fallback.acquiredWealth),
        nisabContinuity: _pick(NisabContinuity.values, j['nisabContinuity'],
            fallback.nisabContinuity),
        wornJewelry: _pick(
            WornJewelryPolicy.values, j['wornJewelry'], fallback.wornJewelry),
        retainedShares: _pick(RetainedSharesPolicy.values, j['retainedShares'],
            fallback.retainedShares),
        debtDeduction: _pick(DebtDeductionPolicy.values, j['debtDeduction'],
            fallback.debtDeduction),
        receivables: _pick(
            ReceivablesPolicy.values, j['receivables'], fallback.receivables),
        rounding: _pick(RoundingPolicy.values, j['rounding'], fallback.rounding),
        rateBasisPoints:
            (j['rateBasisPoints'] as num?)?.toInt() ?? fallback.rateBasisPoints,
      );
}
