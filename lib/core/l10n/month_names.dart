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

  /// Full names, January first.
  static List<String> full({required AppLang lang}) => lang.pick(_ar, _en, _fr);

  /// Short names for tight axes (Arabic names are already short).
  static List<String> short({required AppLang lang}) => lang.pick(
      _ar, <String>[for (final String m in _en) m.substring(0, 3)], _frShort);
}
