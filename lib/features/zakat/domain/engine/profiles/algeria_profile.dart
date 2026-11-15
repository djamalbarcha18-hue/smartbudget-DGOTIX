/// Algeria: the only zakat profile enabled today.
///
/// The official nisab is announced every Hijri year by the Ministry of
/// Religious Affairs and Endowments: 85 g of 18-karat gold at the gram price
/// set by AGENOR (not pure gold). Each value below is for its own year, with
/// its source; add the new announcement when it is published.
library;

import 'package:smartbudget/features/zakat/domain/engine/zakat_profile.dart';
import 'package:smartbudget/features/zakat/domain/engine/zakat_rules.dart';

final ZakatProfile algeriaZakatProfile = ZakatProfile(
  code: 'DZ',
  currency: 'DZD',
  officialNisab: <OfficialNisab>[
    const OfficialNisab(
      hijriYear: 1446,
      amountMinor: 161500000, // 1,615,000 DZD
      currency: 'DZD',
      grams: 85,
      goldKarat: 18,
      gramPriceMinor: 1900000, // 19,000 DZD per 18k gram (AGENOR)
      source: 'وزارة الشؤون الدينية والأوقاف (عبر البلاد)',
      sourceUrl: 'https://www.elbilad.net/s@5telqrar140080',
    ),
    OfficialNisab(
      hijriYear: 1447,
      amountMinor: 229500000, // 2,295,000 DZD
      currency: 'DZD',
      grams: 85,
      goldKarat: 18,
      gramPriceMinor: 2700000, // 27,000 DZD per 18k gram (AGENOR)
      source: 'وزارة الشؤون الدينية والأوقاف (عبر الإذاعة الجزائرية)',
      sourceUrl: 'https://news.radioalgerie.dz/ar/node/88565',
      announcedOn: DateTime(2026, 6, 18),
    ),
  ],
  // Maliki, the school followed in Algeria, with the Ministry's official
  // nisab: approved by the owner on 15 Nov 2026. Retained shares and debt
  // deduction aren't settled by the school: they keep the reviewed choices
  // below. Shown to the user as the method followed, not as a fatwa.
  defaultRules: const ZakatRules(
    version: 'dz-2026.11-maliki',
    approved: true,
    school: ZakatSchool.maliki,
    nisabBasis: NisabBasis.official,
    acquiredWealth: AcquiredWealthPolicy.minimumBalance,
    nisabContinuity: NisabContinuity.throughout,
    wornJewelry: WornJewelryPolicy.exempt,
    retainedShares: RetainedSharesPolicy.zakatablePartElseFullValue,
    debtDeduction: DebtDeductionPolicy.dueByZakatDate,
    receivables: ReceivablesPolicy.onReceipt,
    rounding: RoundingPolicy.halfUp,
  ),
);
