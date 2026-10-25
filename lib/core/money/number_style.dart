/// How amounts are written: the thousands and decimal separators. Digits stay
/// Latin in every style.
enum NumberStyle {
  /// 1,234,567.89
  commaDot(',', '.'),

  /// 1.234.567,89
  dotComma('.', ','),

  /// 1 234 567,89 (a no-break space, so a number never splits across lines)
  spaceComma(' ', ',');

  const NumberStyle(this.group, this.decimal);

  final String group;
  final String decimal;

  /// Rewrites a number written with ',' groups and a '.' decimal (what the
  /// 'en' formatters give) in this style.
  String apply(String en) => this == commaDot
      ? en
      : en.replaceAllMapped(
          RegExp('[,.]'), (Match m) => m[0] == ',' ? group : decimal);

  /// "1,234,567.89" in this style, to show the choice.
  String get sample => apply('1,234,567.89');

  static NumberStyle fromName(String? name) => NumberStyle.values
      .firstWhere((NumberStyle s) => s.name == name, orElse: () => commaDot);
}
