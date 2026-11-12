/// Amounts said as words, turned into digits before the quick entry parser
/// reads them: a speech engine may write «قهوة مئتين» or «courses deux mille
/// cinq cents» rather than «قهوة 200». Arabic (standard and spoken: «ميتين»,
/// «خمسمية», «تلطاش», «ألف ونص»), French and English. Entirely on the device.
///
/// Careful by design, so typed text isn't misread:
/// - Text that already has a digit is left alone («قهوة واحدة 200»).
/// - A lone «one / un / une / واحد» is an article or a count, not an amount.
/// - With several numbers said («two coffees ten dollars»), only the largest
///   becomes digits: the price, not the quantity.
library;

abstract final class SpokenNumbers {
  /// [text] with the amount said in words written as digits, or [text]
  /// unchanged when it has a digit already or no amount said in words.
  static String toDigits(String text) {
    if (RegExp(r'\d').hasMatch(text)) return text;
    final List<String> words =
        text.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).toList();
    if (words.isEmpty) return text;

    // Each word: a list of number parts, a connector («و», «and», «et»), or
    // nothing (null).
    final List<Object?> marks = <Object?>[];
    for (int i = 0; i < words.length; i++) {
      final String w = _clean(words[i]);
      final String next = i + 1 < words.length ? _clean(words[i + 1]) : '';
      if (_connectors.contains(w)) {
        marks.add(_connector);
        continue;
      }
      final List<String> parts =
          w.split('-').where((String p) => p.isNotEmpty).toList();
      final List<_Part> found = <_Part>[];
      bool all = parts.isNotEmpty;
      for (int j = 0; j < parts.length; j++) {
        if (_connectors.contains(parts[j])) continue;
        final _Part? p =
            _partOf(parts[j], j + 1 < parts.length ? parts[j + 1] : next);
        if (p == null) {
          all = false;
          break;
        }
        found.add(p);
      }
      marks.add(all && found.isNotEmpty ? found : null);
    }

    // Runs of number words, a connector allowed between two of them.
    int? bestStart;
    int? bestEnd;
    int bestValue = 0;
    int i = 0;
    while (i < marks.length) {
      final Object? m = marks[i];
      if (m is! List<_Part>) {
        i++;
        continue;
      }
      final int start = i;
      final List<_Part> run = <_Part>[...m];
      i++;
      while (i < marks.length) {
        final Object? here = marks[i];
        if (here is List<_Part>) {
          run.addAll(here);
          i++;
        } else if (identical(here, _connector) &&
            i + 1 < marks.length &&
            marks[i + 1] is List<_Part>) {
          i++;
        } else {
          break;
        }
      }
      final int value = _value(run);
      final bool loneOne = value == 1 && i - start == 1;
      if (value > 0 && !loneOne && value >= bestValue) {
        bestValue = value;
        bestStart = start;
        bestEnd = i;
      }
    }
    if (bestStart == null || bestEnd == null) return text;
    return <String>[
      ...words.sublist(0, bestStart),
      '$bestValue',
      ...words.sublist(bestEnd),
    ].join(' ');
  }

  static const Object _connector = Object();

  static _Part? _partOf(String w, String next) {
    final int? n = _numbers[w];
    if (n != null) return _Part(_Kind.number, n, w);
    if (_hundreds.contains(w)) return _Part(_Kind.hundred, 100, w);
    final int? s = _scales[w];
    if (s != null) return _Part(_Kind.scale, s, w);
    final int? d = _duals[w];
    if (d != null) return _Part(_Kind.dual, d, w);
    if (_halves.contains(w)) return _Part(_Kind.half, 0, w);
    // «a hundred», «a thousand».
    if (w == 'a' &&
        (_hundreds.contains(next) || _scales.containsKey(next))) {
      return _Part(_Kind.number, 1, w);
    }
    // Arabic «و» (and) or «ب» (for) written onto the number: «وعشرين»,
    // «بخمسين».
    if (w.length > 2 && (w.startsWith('و') || w.startsWith('ب'))) {
      return _partOf(w.substring(1), next);
    }
    return null;
  }

  static int _value(List<_Part> run) {
    int total = 0;
    int current = 0;
    int last = 0; // the last hundred or scale, for «ونص» (and a half)
    int? lastAdded; // for French «quatre-vingt»
    for (final _Part p in run) {
      switch (p.kind) {
        case _Kind.number:
          if (p.value == 20 && lastAdded == 4 && p.word.startsWith('vingt')) {
            current += 76; // quatre (4) + vingt → 80
            lastAdded = 80;
          } else {
            current += p.value;
            if (p.value >= 100) last = 100;
            lastAdded = p.value;
          }
        case _Kind.hundred:
          current = (current == 0 ? 1 : current) * 100;
          last = 100;
          lastAdded = null;
        case _Kind.scale:
          total += (current == 0 ? 1 : current) * p.value;
          current = 0;
          last = p.value;
          lastAdded = null;
        case _Kind.dual:
          total += p.value;
          last = p.value ~/ 2;
          lastAdded = null;
        case _Kind.half:
          if (last >= 1000) {
            total += last ~/ 2;
          } else if (last == 100) {
            current += 50;
          }
      }
    }
    return total + current;
  }

  /// Lower-case, without edge punctuation, Arabic diacritics and tatweel, and
  /// with the letter variants a speech engine may use made one (أ إ آ → ا,
  /// ى → ي, ة → ه).
  static String _clean(String w) => w
      .toLowerCase()
      .replaceAll(RegExp(r'^[.,!?،؛:«»"()]+|[.,!?،؛:«»"()]+$'), '')
      .replaceAll(RegExp('[\u064B-\u0652\u0640]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');

  static Map<String, int> _table(Map<int, List<String>> m) => <String, int>{
        for (final MapEntry<int, List<String>> e in m.entries)
          for (final String w in e.value) _clean(w): e.key,
      };

  static Set<String> _set(List<String> ws) => ws.map(_clean).toSet();

  static final Set<String> _connectors = _set(<String>['و', 'and', 'et']);

  static final Map<String, int> _numbers = _table(<int, List<String>>{
    // Arabic, standard and spoken.
    1: <String>['واحد', 'واحدة'],
    2: <String>['اثنين', 'اثنان', 'إثنين', 'اثنتين', 'اتنين', 'زوز'],
    3: <String>['ثلاثة', 'ثلاث', 'تلاتة', 'تلاثة'],
    4: <String>['أربعة', 'أربع', 'ربعة'],
    5: <String>['خمسة', 'خمس'],
    6: <String>['ستة', 'ست'],
    7: <String>['سبعة', 'سبع'],
    8: <String>['ثمانية', 'ثمان', 'ثماني', 'تمانية', 'ثمنية', 'تمنية'],
    9: <String>['تسعة', 'تسع'],
    10: <String>['عشرة', 'عشر'],
    11: <String>['حداش', 'حداعش', 'احداش'],
    12: <String>['طناش', 'اطناش', 'اثناعش'],
    13: <String>['تلطاش', 'ثلطاش'],
    14: <String>['ربعطاش', 'اربعطاش'],
    15: <String>['خمسطاش'],
    16: <String>['سطاش'],
    17: <String>['سبعطاش'],
    18: <String>['تمنطاش', 'ثمنطاش'],
    19: <String>['تسعطاش'],
    20: <String>['عشرين', 'عشرون'],
    30: <String>['ثلاثين', 'ثلاثون', 'تلاتين', 'تلاثين'],
    40: <String>['أربعين', 'أربعون', 'ربعين'],
    50: <String>['خمسين', 'خمسون'],
    60: <String>['ستين', 'ستون'],
    70: <String>['سبعين', 'سبعون'],
    80: <String>['ثمانين', 'ثمانون', 'تمانين'],
    90: <String>['تسعين', 'تسعون'],
    200: <String>['مئتين', 'مئتان', 'مائتين', 'مائتان', 'ميتين', 'متين'],
    300: <String>['ثلاثمائة', 'ثلاثمئة', 'ثلاثمية', 'تلتمية', 'تلاتمية'],
    400: <String>['أربعمائة', 'أربعمئة', 'ربعمية', 'اربعمية'],
    500: <String>['خمسمائة', 'خمسمئة', 'خمسمية'],
    600: <String>['ستمائة', 'ستمئة', 'ستمية'],
    700: <String>['سبعمائة', 'سبعمئة', 'سبعمية'],
    800: <String>['ثمانمائة', 'ثمانمئة', 'ثمنمية', 'تمنمية'],
    900: <String>['تسعمائة', 'تسعمئة', 'تسعمية'],
    0: <String>['zero', 'zéro'],
  })
    ..addAll(_table(<int, List<String>>{
      20: <String>['twenty', 'vingt', 'vingts'],
      30: <String>['thirty', 'trente'],
      40: <String>['forty', 'quarante'],
      50: <String>['fifty', 'cinquante'],
      60: <String>['sixty', 'soixante'],
      70: <String>['seventy', 'septante'],
      80: <String>['eighty', 'huitante', 'octante'],
      90: <String>['ninety', 'nonante'],
      // French one … sixteen (17–19 are «dix-sept» …).
      1: <String>['one', 'un', 'une'],
      2: <String>['two', 'deux'],
      3: <String>['three', 'trois'],
      4: <String>['four', 'quatre'],
      5: <String>['five', 'cinq'],
      6: <String>['six'],
      7: <String>['seven', 'sept'],
      8: <String>['eight', 'huit'],
      9: <String>['nine', 'neuf'],
      10: <String>['ten', 'dix'],
      11: <String>['eleven', 'onze'],
      12: <String>['twelve', 'douze'],
      13: <String>['thirteen', 'treize'],
      14: <String>['fourteen', 'quatorze'],
      15: <String>['fifteen', 'quinze'],
      16: <String>['sixteen', 'seize'],
    }));

  static final Set<String> _hundreds = _set(<String>[
    'مائة', 'مئة', 'مية', 'ميه', 'مايه', 'hundred', 'hundreds', 'cent',
    'cents',
  ]);

  static final Map<String, int> _scales = _table(<int, List<String>>{
    1000: <String>[
      'ألف', 'آلاف', 'ألاف', 'thousand', 'thousands', 'mille', 'milles',
    ],
    1000000: <String>['مليون', 'ملايين', 'million', 'millions'],
    1000000000: <String>[
      'مليار', 'مليارات', 'billion', 'billions', 'milliard', 'milliards',
    ],
  });

  static final Map<String, int> _duals = _table(<int, List<String>>{
    2000: <String>['ألفين', 'ألفان'],
    2000000: <String>['مليونين', 'مليونان'],
  });

  static final Set<String> _halves = _set(<String>['نص', 'نصف']);
}

enum _Kind { number, hundred, scale, dual, half }

class _Part {
  const _Part(this.kind, this.value, this.word);
  final _Kind kind;
  final int value;
  final String word;
}
