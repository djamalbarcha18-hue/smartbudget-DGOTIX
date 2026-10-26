import 'package:smartbudget/core/l10n/app_lang.dart';

/// Gregorian month names used across the UI (selectors, chart axes).
abstract final class MonthNames {
  static const List<String> _ar = <String>[
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', //
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const List<String> _en = <String>[
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _fr = <String>[
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', //
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const List<String> _frShort = <String>[
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', //
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static const List<String> _id = <String>[
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> _idShort = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _es = <String>[
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', //
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  static const List<String> _esShort = <String>[
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
    'jul', 'ago', 'sept', 'oct', 'nov', 'dic',
  ];

  static const List<String> _tr = <String>[
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  static const List<String> _trShort = <String>[
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', //
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  static const List<String> _ms = <String>[
    'Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun', //
    'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember',
  ];
  static const List<String> _msShort = <String>[
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
  ];

  static const List<String> _de = <String>[
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', //
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];
  static const List<String> _deShort = <String>[
    'Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', //
    'Juli', 'Aug.', 'Sep.', 'Okt.', 'Nov.', 'Dez.',
  ];

  static const List<String> _pt = <String>[
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const List<String> _ptShort = <String>[
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  static const List<String> _it = <String>[
    'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', //
    'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
  ];
  static const List<String> _itShort = <String>[
    'gen', 'feb', 'mar', 'apr', 'mag', 'giu', //
    'lug', 'ago', 'set', 'ott', 'nov', 'dic',
  ];

  static const List<String> _nl = <String>[
    'januari', 'februari', 'maart', 'april', 'mei', 'juni', //
    'juli', 'augustus', 'september', 'oktober', 'november', 'december',
  ];
  static const List<String> _nlShort = <String>[
    'jan', 'feb', 'mrt', 'apr', 'mei', 'jun', //
    'jul', 'aug', 'sep', 'okt', 'nov', 'dec',
  ];

  static const List<String> _bs = <String>[
    'januar', 'februar', 'mart', 'april', 'maj', 'juni', //
    'juli', 'august', 'septembar', 'oktobar', 'novembar', 'decembar',
  ];
  static const List<String> _bsShort = <String>[
    'jan', 'feb', 'mar', 'apr', 'maj', 'jun', //
    'jul', 'aug', 'sep', 'okt', 'nov', 'dec',
  ];

  static const List<String> _sq = <String>[
    'janar', 'shkurt', 'mars', 'prill', 'maj', 'qershor', //
    'korrik', 'gusht', 'shtator', 'tetor', 'nëntor', 'dhjetor',
  ];
  static const List<String> _sqShort = <String>[
    'jan', 'shk', 'mar', 'pri', 'maj', 'qer', //
    'korr', 'gush', 'sht', 'tet', 'nën', 'dhj',
  ];

  // Standalone (nominative) forms: the app shows months on their own, as in
  // "Октябрь 2026".
  static const List<String> _ru = <String>[
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', //
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];
  static const List<String> _ruShort = <String>[
    'янв', 'фев', 'мар', 'апр', 'май', 'июн', //
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  static const List<String> _sw = <String>[
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni', //
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];
  static const List<String> _swShort = <String>[
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _ha = <String>[
    'Janairu', 'Faburairu', 'Maris', 'Afirilu', 'Mayu', 'Yuni', //
    'Yuli', 'Agusta', 'Satumba', 'Oktoba', 'Nuwamba', 'Disamba',
  ];
  static const List<String> _haShort = <String>[
    'Jan', 'Fab', 'Mar', 'Afi', 'May', 'Yun', //
    'Yul', 'Agu', 'Sat', 'Okt', 'Nuw', 'Dis',
  ];

  static const List<String> _af = <String>[
    'Januarie', 'Februarie', 'Maart', 'April', 'Mei', 'Junie', //
    'Julie', 'Augustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> _afShort = <String>[
    'Jan', 'Feb', 'Mrt', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _fa = <String>[
    'ژانویه',
    'فوریه',
    'مارس',
    'آوریل',
    'مه',
    'ژوئن',
    'ژوئیه',
    'اوت',
    'سپتامبر',
    'اکتبر',
    'نوامبر',
    'دسامبر',
  ];
  static const List<String> _faShort = <String>[
    'ژانویه',
    'فوریه',
    'مارس',
    'آوریل',
    'مه',
    'ژوئن',
    'ژوئیه',
    'اوت',
    'سپتامبر',
    'اکتبر',
    'نوامبر',
    'دسامبر',
  ];

  static const List<String> _hi = <String>[
    'जनवरी',
    'फ़रवरी',
    'मार्च',
    'अप्रैल',
    'मई',
    'जून',
    'जुलाई',
    'अगस्त',
    'सितंबर',
    'अक्टूबर',
    'नवंबर',
    'दिसंबर',
  ];
  static const List<String> _hiShort = <String>[
    'जन॰',
    'फ़र॰',
    'मार्च',
    'अप्रैल',
    'मई',
    'जून',
    'जुल॰',
    'अग॰',
    'सित॰',
    'अक्टू॰',
    'नव॰',
    'दिस॰',
  ];

  static const List<String> _zh = <String>[
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ];
  static const List<String> _zhShort = <String>[
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];

  static const List<String> _ja = <String>[
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];
  static const List<String> _jaShort = <String>[
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];

  static const List<String> _ko = <String>[
    '1월',
    '2월',
    '3월',
    '4월',
    '5월',
    '6월',
    '7월',
    '8월',
    '9월',
    '10월',
    '11월',
    '12월',
  ];
  static const List<String> _koShort = <String>[
    '1월',
    '2월',
    '3월',
    '4월',
    '5월',
    '6월',
    '7월',
    '8월',
    '9월',
    '10월',
    '11월',
    '12월',
  ];

  // Urdu names are short enough for the axes too.
  static const List<String> _ur = <String>[
    'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', //
    'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر',
  ];

  /// Full names, January first.
  static List<String> full({required AppLang lang}) => lang.pick(_ar, _en,
      fr: _fr,
      id: _id,
      es: _es,
      tr: _tr,
      ms: _ms,
      ur: _ur,
      de: _de,
      pt: _pt,
      it: _it,
      nl: _nl,
      bs: _bs,
      sq: _sq,
      ru: _ru,
      sw: _sw,
      ha: _ha,
      af: _af,
      fa: _fa,
      hi: _hi,
      zh: _zh,
      ja: _ja,
      ko: _ko);

  /// Short names for tight axes (Arabic and Urdu names are already short).
  static List<String> short({required AppLang lang}) =>
      lang.pick(_ar, <String>[for (final String m in _en) m.substring(0, 3)],
          fr: _frShort,
          id: _idShort,
          es: _esShort,
          tr: _trShort,
          ms: _msShort,
          ur: _ur,
          de: _deShort,
          pt: _ptShort,
          it: _itShort,
          nl: _nlShort,
          bs: _bsShort,
          sq: _sqShort,
          ru: _ruShort,
          sw: _swShort,
          ha: _haShort,
          af: _afShort,
          fa: _faShort,
          hi: _hiShort,
          zh: _zhShort,
          ja: _jaShort,
          ko: _koShort);
}
