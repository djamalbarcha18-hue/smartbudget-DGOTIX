import 'package:smartbudget/core/l10n/app_lang.dart';

/// Pure Hijri (Islamic) calendar conversion using the tabular "Kuwaiti"
/// algorithm — deterministic, dependency-free and unit-tested. Used for the
/// zakat hawl (a full lunar year), which is the sharia basis rather than the
/// Gregorian year.
///
/// Note: this is the arithmetical (tabular) calendar; sighting-based dates can
/// differ by ±1 day. It is exact and self-consistent for computing "one lunar
/// year later", which is what the hawl needs.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  /// 1..(12), 1-based Hijri month; [year] is the Hijri year; [day] 1..30.
  final int year;
  final int month;
  final int day;

  static const List<String> monthsAr = <String>[
    'محرّم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوّال',
    'ذو القعدة',
    'ذو الحِجّة',
  ];
  static const List<String> monthsEn = <String>[
    'Muharram',
    'Safar',
    'Rabiʻ I',
    'Rabiʻ II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Shaʻban',
    'Ramadan',
    'Shawwal',
    'Dhuʻl-Qiʻdah',
    'Dhuʻl-Hijjah',
  ];

  static const List<String> monthsFr = <String>[
    'Mouharram',
    'Safar',
    'Rabiʻ al-awwal',
    'Rabiʻ ath-thani',
    'Joumada al-oula',
    'Joumada ath-thania',
    'Rajab',
    'Chaʻbane',
    'Ramadan',
    'Chawwal',
    'Dhou al-qiʻda',
    'Dhou al-hijja',
  ];

  static const List<String> monthsId = <String>[
    'Muharam', 'Safar', 'Rabiulawal', 'Rabiulakhir', 'Jumadilawal',
    'Jumadilakhir', 'Rajab', 'Syakban', 'Ramadan', 'Syawal', 'Zulkaidah',
    'Zulhijah',
  ];

  static const List<String> monthsEs = <String>[
    'Muharram', 'Safar', 'Rabi al-Awal', 'Rabi al-Zani', 'Yumada al-Ula',
    'Yumada al-Zania', 'Rayab', 'Shaabán', 'Ramadán', 'Shawwal',
    'Du al-Qada', 'Du al-Hiya',
  ];

  static const List<String> monthsTr = <String>[
    'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir', 'Cemaziyelevvel',
    'Cemaziyelahir', 'Recep', 'Şaban', 'Ramazan', 'Şevval', 'Zilkade',
    'Zilhicce',
  ];

  static const List<String> monthsMs = <String>[
    'Muharam', 'Safar', 'Rabiulawal', 'Rabiulakhir', 'Jamadilawal',
    'Jamadilakhir', 'Rejab', 'Syaaban', 'Ramadan', 'Syawal', 'Zulkaedah',
    'Zulhijah',
  ];

  static const List<String> monthsUr = <String>[
    'محرم', 'صفر', 'ربیع الاول', 'ربیع الثانی', 'جمادی الاول',
    'جمادی الثانی', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذوالقعدہ',
    'ذوالحجہ',
  ];

  static const List<String> monthsDe = <String>[
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi ath-Thani', 'Dschumada al-Ula',
    'Dschumada ath-Thaniya', 'Radschab', 'Schaban', 'Ramadan', 'Schawwal',
    'Dhu l-Qada', 'Dhu l-Hiddscha',
  ];

  static const List<String> monthsPt = <String>[
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Ula',
    'Jumada al-Thania', 'Rajab', 'Shaaban', 'Ramadã', 'Shawwal',
    'Dhu al-Qada', 'Dhu al-Hijja',
  ];

  static const List<String> monthsIt = <String>[
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Ula',
    'Jumada al-Thaniya', 'Rajab', 'Shaban', 'Ramadan', 'Shawwal',
    'Dhu al-Qada', 'Dhu al-Hijja',
  ];

  static const List<String> monthsNl = <String>[
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Djoemada al-Oela',
    'Djoemada al-Thania', 'Radjab', 'Sjaban', 'Ramadan', 'Sjawwal',
    'Dhoel-Qada', 'Dhoel-Hidja',
  ];

  static const List<String> monthsBs = <String>[
    'Muharrem', 'Safer', 'Rebiu-l-evvel', 'Rebiu-l-ahir', 'Džumade-l-ula',
    'Džumade-l-uhra', 'Redžeb', 'Ša\'ban', 'Ramazan', 'Ševval', 'Zu-l-ka\'de',
    'Zu-l-hidždže',
  ];

  String monthName({required AppLang lang}) => (month >= 1 && month <= 12)
      ? lang.pick(monthsAr, monthsEn,
          fr: monthsFr, id: monthsId, es: monthsEs,
          tr: monthsTr, ms: monthsMs, ur: monthsUr, de: monthsDe,
          pt: monthsPt, it: monthsIt,
          nl: monthsNl, bs: monthsBs)[month - 1]
      : '';

  /// Formats as `day month year هـ`, e.g. "12 رمضان 1446 هـ".
  String format({required AppLang lang}) => lang.pick(
      '$day ${monthName(lang: lang)} $year هـ',
      '$day ${monthName(lang: lang)} $year AH',
      fr: '$day ${monthName(lang: lang)} $year H',
      id: '$day ${monthName(lang: lang)} $year H',
      es: '$day ${monthName(lang: lang)} $year H',
      tr: '$day ${monthName(lang: lang)} $year H',
      ms: '$day ${monthName(lang: lang)} $year H',
      ur: '$day ${monthName(lang: lang)} $year ہجری',
      de: '$day. ${monthName(lang: lang)} $year n. H.',
      pt: '$day de ${monthName(lang: lang)} de $year H',
      it: '$day ${monthName(lang: lang)} $year E.',
      nl: '$day ${monthName(lang: lang)} $year H.',
      bs: '$day. ${monthName(lang: lang)} $year. h. g.');

  /// Julian Day Number for this Hijri date (tabular civil calendar).
  int toJdn() =>
      (11 * year + 3) ~/ 30 +
      354 * year +
      30 * month -
      (month - 1) ~/ 2 +
      day +
      1948440 -
      385;

  /// The Gregorian date (date-only, local) for this Hijri date.
  DateTime toGregorian() => _jdnToGregorian(toJdn());

  /// One Hijri (lunar) year later, same month/day — the hawl completion anchor.
  HijriDate addYears(int n) => HijriDate(year + n, month, day);

  /// Converts a Gregorian date (its Y/M/D, ignoring time) to Hijri.
  static HijriDate fromGregorian(DateTime g) {
    final int jdn = _gregorianToJdn(g.year, g.month, g.day);
    int l = jdn - 1948440 + 10632;
    final int n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final int j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final int month = (24 * l) ~/ 709;
    final int day = l - (709 * month) ~/ 24;
    final int year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }

  static int _gregorianToJdn(int year, int month, int day) {
    final int a = (14 - month) ~/ 12;
    final int y = year + 4800 - a;
    final int m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    int l = jdn + 68569;
    final int n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    final int i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    final int j = (80 * l) ~/ 2447;
    final int day = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    final int month = j + 2 - 12 * l;
    final int year = 100 * (n - 49) + i + l;
    return DateTime(year, month, day);
  }
}
