/// Classifies expense categories as essential vs discretionary for the health
/// engine. This is a semantic classification of the app's stored category keys
/// (not currency- or country-specific), used to compute essential monthly
/// expenses (for emergency coverage) and discretionary discipline.
///
/// Savings/charity outflows (savings & investment, zakat, charity, Hajj) are
/// treated as neither essential need nor discretionary consumption, so they do
/// not distort the "living costs" figures.
abstract final class HealthCategories {
  /// Stored category keys that are essential living costs / obligations.
  static const Set<String> essential = <String>{
    'الطعام', // groceries
    'النقل', // transport
    'السكن', // housing
    'الفواتير', // bills & utilities
    'الاتصالات والإنترنت', // telecom & internet
    'الصحة', // health
    'التعليم', // education
    'الأطفال والعائلة', // children & family
    'الأقساط والقروض', // loans & installments (debt service)
    'التأمين', // insurance
    'الضرائب والرسوم', // taxes & fees
    'الوقود', // fuel
    'الصيانة والإصلاح', // maintenance & repairs
    'الطوارئ', // emergency
  };

  /// Outflows that are saving/charity, not consumption — excluded from both
  /// essential and discretionary living costs.
  static const Set<String> savingOrGiving = <String>{
    'الادخار والاستثمار', // savings & investment
    'صدقة وتبرّعات', // charity & donations
    'زكاة', // zakat
    'الحج والعمرة', // Hajj & Umrah
  };

  /// The debt-service category (its outflow is the monthly debt payment).
  static const String debtService = 'الأقساط والقروض';

  static bool isEssential(String category) => essential.contains(category);

  static bool isSavingOrGiving(String category) =>
      savingOrGiving.contains(category);

  /// Discretionary = an expense that is neither essential nor saving/giving.
  static bool isDiscretionary(String category) =>
      !isEssential(category) && !isSavingOrGiving(category);
}
