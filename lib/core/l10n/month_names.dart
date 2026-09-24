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

  /// Full names, January first.
  static List<String> full({required bool ar}) => ar ? _ar : _en;

  /// Short names for tight axes (Arabic names are already short).
  static List<String> short({required bool ar}) =>
      ar ? _ar : <String>[for (final String m in _en) m.substring(0, 3)];
}
