/// Amounts said as words, turned into digits before the quick entry parser
/// reads them: a speech engine may write «قهوة مئتين» or «courses deux mille
/// cinq cents» rather than «قهوة 200». Entirely on the device, no AI.
///
/// Languages: Arabic, standard and the main spoken varieties — Maghrebi
/// («ميتين», «تلطاش», «جوج»), Egyptian («تلات تلاف», «خمستاشر»), Levantine
/// («تنين», «خمسطعش»), Gulf and Iraqi («ثنعش») — with «ونص» and «وربع»;
/// French; English; Hindi and Urdu (each number 1–99 is its own word, plus
/// डेढ़ / ڈیڑھ 1½, ढाई / ڈھائی 2½, साढ़े / ساڑھے +½, सवा / سوا +¼, पौने / پونے −¼,
/// लाख / لاکھ, करोड़ / کروڑ); Persian; Turkish; Indonesian and Malay
/// («dua puluh lima ribu»).
///
/// Careful by design, so typed text isn't misread:
/// - Text that already has a digit is left alone («قهوة واحدة 200»).
/// - A lone «one / un / واحد» is an article or a count, not an amount; so are
///   a few words that mean something else alone (see [_notAlone]).
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

    // Each word: its number parts, a connector («و», «and», «et»), or null.
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

    // Runs of number words, a connector allowed between two of them; the
    // largest run is the amount.
    int? bestStart;
    int? bestEnd;
    double bestValue = 0;
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
      final double value = _value(run);
      final bool alone = i - start == 1 &&
          run.length == 1 &&
          (value == 1 || _notAlone.contains(run.first.word));
      if (value > 0 && !alone && value >= bestValue) {
        bestValue = value;
        bestStart = start;
        bestEnd = i;
      }
    }
    if (bestStart == null || bestEnd == null) return text;
    final String digits = bestValue == bestValue.roundToDouble()
        ? '${bestValue.round()}'
        : '$bestValue';
    return <String>[
      ...words.sublist(0, bestStart),
      digits,
      ...words.sublist(bestEnd),
    ].join(' ');
  }

  static const Object _connector = Object();

  static _Part? _partOf(String w, String next) {
    final double? n = _numbers[w];
    if (n != null) return _Part(_Kind.number, n, w);
    final double? a = _adjusts[w];
    if (a != null) return _Part(_Kind.adjust, a, w);
    if (_hundreds.contains(w)) return _Part(_Kind.hundred, 100, w);
    final double? s = _scales[w];
    if (s != null) return _Part(_Kind.scale, s, w);
    final double? d = _duals[w];
    if (d != null) return _Part(_Kind.dual, d, w);
    if (_halves.contains(w)) return _Part(_Kind.half, 0, w);
    if (_quarters.contains(w)) return _Part(_Kind.quarter, 0, w);
    if (_tens.contains(w)) return _Part(_Kind.tens, 0, w);
    if (_teens.contains(w)) return _Part(_Kind.teen, 0, w);
    // «a hundred», «a thousand».
    if (w == 'a' && (_hundreds.contains(next) || _scales.containsKey(next))) {
      return _Part(_Kind.number, 1, w);
    }
    // Arabic «و» (and) or «ب» (for) written onto the number: «وعشرين»,
    // «بخمسين».
    if (w.length > 2 && (w.startsWith('و') || w.startsWith('ب'))) {
      return _partOf(w.substring(1), next);
    }
    return null;
  }

  static double _value(List<_Part> run) {
    double total = 0;
    double hundreds = 0; // under a thousand: the hundreds…
    double small = 0; // …and the part below a hundred
    double last = 0; // the last hundred or scale, for «ونص» / «وربع»
    double? lastAdded; // for French «quatre-vingt»
    double adjust = 0; // साढ़े / सवा / पौने before the next number
    for (final _Part p in run) {
      switch (p.kind) {
        case _Kind.number:
          if (p.value == 20 && lastAdded == 4 && p.word.startsWith('vingt')) {
            small += 76; // quatre (4) + vingt → 80
            lastAdded = 80;
          } else if (p.value >= 100) {
            hundreds += p.value + adjust;
            last = 100;
            lastAdded = p.value;
          } else {
            small += p.value + adjust;
            lastAdded = p.value;
          }
          adjust = 0;
        case _Kind.adjust:
          adjust = p.value;
        case _Kind.hundred:
          hundreds += (small == 0 ? 1 + adjust : small) * 100;
          small = 0;
          adjust = 0;
          last = 100;
          lastAdded = null;
        case _Kind.tens:
          small = (small == 0 ? 1 : small) * 10;
          lastAdded = null;
        case _Kind.teen:
          small += 10;
          lastAdded = null;
        case _Kind.scale:
          final double under = hundreds + small;
          total += (under == 0 ? 1 + adjust : under) * p.value;
          hundreds = 0;
          small = 0;
          adjust = 0;
          last = p.value;
          lastAdded = null;
        case _Kind.dual:
          total += p.value;
          last = p.value >= 2000 ? p.value / 2 : p.value;
          lastAdded = null;
        case _Kind.half:
          if (last >= 1000) {
            total += last / 2;
          } else if (last == 100) {
            small += 50;
          }
        case _Kind.quarter:
          if (last >= 1000) {
            total += last / 4;
          } else if (last == 100) {
            small += 25;
          }
      }
    }
    return total + hundreds + small;
  }

  /// Lower-case, without edge punctuation and Arabic-script diacritics, with
  /// the letter variants a speech engine may use made one (أ إ آ ٱ → ا;
  /// ى ی ي → ي; ة ۃ ہ ه → ه; ک → ك) and, in Devanagari, no nukta and one
  /// nasal mark (पाँच = पांच, हज़ार = हजार).
  static String _clean(String w) => w
      .toLowerCase()
      .replaceAll(RegExp(r'^[.,!?،؛:«»"()।]+|[.,!?،؛:«»"()।]+$'), '')
      .replaceAll(RegExp('[\u064B-\u0652\u0640\u0670]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll(RegExp('[ىیي]'), 'ي')
      .replaceAll(RegExp('[ةۃہه]'), 'ه')
      .replaceAll('ک', 'ك')
      .replaceAll('\u093C', '')
      .replaceAll('\u0901', '\u0902');

  static Map<String, double> _table(Map<double, List<String>> m) =>
      <String, double>{
        for (final MapEntry<double, List<String>> e in m.entries)
          for (final String w in e.value) _clean(w): e.key,
      };

  static Set<String> _set(List<String> ws) => ws.map(_clean).toSet();

  // Arabic, standard and spoken
  static final Map<String, double> _n0 = _table(<double, List<String>>{
    1.0: <String>['واحد', 'واحدة'],
    2.0: <String>['اثنين', 'اثنان', 'إثنين', 'اثنتين', 'اتنين', 'زوز', 'جوج', 'تنين', 'ثنين'],
    3.0: <String>['ثلاثة', 'ثلاث', 'تلاتة', 'تلاثة', 'تلات', 'تلت'],
    4.0: <String>['أربعة', 'أربع', 'ربعة'],
    5.0: <String>['خمسة', 'خمس'],
    6.0: <String>['ستة', 'ست'],
    7.0: <String>['سبعة', 'سبع'],
    8.0: <String>['ثمانية', 'ثمان', 'ثماني', 'تمانية', 'ثمنية', 'تمنية'],
    9.0: <String>['تسعة', 'تسع'],
    10.0: <String>['عشرة', 'عشر'],
    11.0: <String>['حداش', 'حداعش', 'احداش', 'حضاش', 'حداشر', 'احداشر', 'حدعش', 'احدعش', 'احدعشر'],
    12.0: <String>['طناش', 'اطناش', 'اثناعش', 'اتناشر', 'اطناشر', 'تنعش', 'ثنعش', 'اثنعش', 'اثنعشر'],
    13.0: <String>['تلطاش', 'ثلطاش', 'تلتاشر', 'تلاتاشر', 'تلتعش', 'ثلطعش'],
    14.0: <String>['ربعطاش', 'اربعطاش', 'اربعتاشر', 'اربعطعش', 'اربطعش'],
    15.0: <String>['خمسطاش', 'خمستاشر', 'خمسطعش'],
    16.0: <String>['سطاش', 'ستاشر', 'سطعش', 'ستطعش'],
    17.0: <String>['سبعطاش', 'سبعتاشر', 'سبعطعش'],
    18.0: <String>['تمنطاش', 'ثمنطاش', 'تمنتاشر', 'تمنطعش', 'ثمنطعش'],
    19.0: <String>['تسعطاش', 'تسعتاشر', 'تسعطعش'],
    20.0: <String>['عشرين', 'عشرون'],
    30.0: <String>['ثلاثين', 'ثلاثون', 'تلاتين', 'تلاثين'],
    40.0: <String>['أربعين', 'أربعون', 'ربعين'],
    50.0: <String>['خمسين', 'خمسون'],
    60.0: <String>['ستين', 'ستون'],
    70.0: <String>['سبعين', 'سبعون'],
    80.0: <String>['ثمانين', 'ثمانون', 'تمانين'],
    90.0: <String>['تسعين', 'تسعون'],
    200.0: <String>['مئتين', 'مئتان', 'مائتين', 'مائتان', 'ميتين', 'متين'],
    300.0: <String>['ثلاثمائة', 'ثلاثمئة', 'ثلاثمية', 'تلتمية', 'تلاتمية', 'ثلثمية'],
    400.0: <String>['أربعمائة', 'أربعمئة', 'ربعمية', 'اربعمية'],
    500.0: <String>['خمسمائة', 'خمسمئة', 'خمسمية'],
    600.0: <String>['ستمائة', 'ستمئة', 'ستمية'],
    700.0: <String>['سبعمائة', 'سبعمئة', 'سبعمية'],
    800.0: <String>['ثمانمائة', 'ثمانمئة', 'ثمنمية', 'تمنمية'],
    900.0: <String>['تسعمائة', 'تسعمئة', 'تسعمية'],
  });

  // English
  static final Map<String, double> _n1 = _table(<double, List<String>>{
    0.0: <String>['zero'],
    1.0: <String>['one'],
    2.0: <String>['two'],
    3.0: <String>['three'],
    4.0: <String>['four'],
    5.0: <String>['five'],
    6.0: <String>['six'],
    7.0: <String>['seven'],
    8.0: <String>['eight'],
    9.0: <String>['nine'],
    10.0: <String>['ten'],
    11.0: <String>['eleven'],
    12.0: <String>['twelve'],
    13.0: <String>['thirteen'],
    14.0: <String>['fourteen'],
    15.0: <String>['fifteen'],
    16.0: <String>['sixteen'],
    17.0: <String>['seventeen'],
    18.0: <String>['eighteen'],
    19.0: <String>['nineteen'],
    20.0: <String>['twenty'],
    30.0: <String>['thirty'],
    40.0: <String>['forty'],
    50.0: <String>['fifty'],
    60.0: <String>['sixty'],
    70.0: <String>['seventy'],
    80.0: <String>['eighty'],
    90.0: <String>['ninety'],
  });

  // French
  static final Map<String, double> _n2 = _table(<double, List<String>>{
    0.0: <String>['zéro'],
    1.0: <String>['un', 'une'],
    2.0: <String>['deux'],
    3.0: <String>['trois'],
    4.0: <String>['quatre'],
    5.0: <String>['cinq'],
    6.0: <String>['six'],
    7.0: <String>['sept'],
    8.0: <String>['huit'],
    9.0: <String>['neuf'],
    10.0: <String>['dix'],
    11.0: <String>['onze'],
    12.0: <String>['douze'],
    13.0: <String>['treize'],
    14.0: <String>['quatorze'],
    15.0: <String>['quinze'],
    16.0: <String>['seize'],
    20.0: <String>['vingt', 'vingts'],
    30.0: <String>['trente'],
    40.0: <String>['quarante'],
    50.0: <String>['cinquante'],
    60.0: <String>['soixante'],
    70.0: <String>['septante'],
    80.0: <String>['huitante', 'octante'],
    90.0: <String>['nonante'],
  });

  // Hindi
  static final Map<String, double> _n3 = _table(<double, List<String>>{
    1.0: <String>['एक'],
    2.0: <String>['दो'],
    3.0: <String>['तीन'],
    4.0: <String>['चार'],
    5.0: <String>['पांच', 'पाँच'],
    6.0: <String>['छह', 'छः', 'छे'],
    7.0: <String>['सात'],
    8.0: <String>['आठ'],
    9.0: <String>['नौ', 'नो'],
    10.0: <String>['दस'],
    11.0: <String>['ग्यारह'],
    12.0: <String>['बारह'],
    13.0: <String>['तेरह'],
    14.0: <String>['चौदह'],
    15.0: <String>['पंद्रह', 'पन्द्रह'],
    16.0: <String>['सोलह'],
    17.0: <String>['सत्रह', 'सतरह'],
    18.0: <String>['अठारह'],
    19.0: <String>['उन्नीस'],
    20.0: <String>['बीस'],
    21.0: <String>['इक्कीस'],
    22.0: <String>['बाईस'],
    23.0: <String>['तेईस'],
    24.0: <String>['चौबीस'],
    25.0: <String>['पच्चीस'],
    26.0: <String>['छब्बीस'],
    27.0: <String>['सत्ताईस'],
    28.0: <String>['अट्ठाईस'],
    29.0: <String>['उनतीस'],
    30.0: <String>['तीस'],
    31.0: <String>['इकतीस'],
    32.0: <String>['बत्तीस'],
    33.0: <String>['तैंतीस'],
    34.0: <String>['चौंतीस'],
    35.0: <String>['पैंतीस'],
    36.0: <String>['छत्तीस'],
    37.0: <String>['सैंतीस'],
    38.0: <String>['अड़तीस'],
    39.0: <String>['उनतालीस'],
    40.0: <String>['चालीस'],
    41.0: <String>['इकतालीस'],
    42.0: <String>['बयालीस'],
    43.0: <String>['तैंतालीस'],
    44.0: <String>['चौवालीस'],
    45.0: <String>['पैंतालीस'],
    46.0: <String>['छियालीस'],
    47.0: <String>['सैंतालीस'],
    48.0: <String>['अड़तालीस'],
    49.0: <String>['उनचास'],
    50.0: <String>['पचास'],
    51.0: <String>['इक्यावन'],
    52.0: <String>['बावन'],
    53.0: <String>['तिरपन'],
    54.0: <String>['चौवन'],
    55.0: <String>['पचपन'],
    56.0: <String>['छप्पन'],
    57.0: <String>['सत्तावन'],
    58.0: <String>['अट्ठावन'],
    59.0: <String>['उनसठ'],
    60.0: <String>['साठ'],
    61.0: <String>['इकसठ'],
    62.0: <String>['बासठ'],
    63.0: <String>['तिरसठ'],
    64.0: <String>['चौंसठ'],
    65.0: <String>['पैंसठ'],
    66.0: <String>['छियासठ'],
    67.0: <String>['सड़सठ'],
    68.0: <String>['अड़सठ'],
    69.0: <String>['उनहत्तर'],
    70.0: <String>['सत्तर'],
    71.0: <String>['इकहत्तर'],
    72.0: <String>['बहत्तर'],
    73.0: <String>['तिहत्तर'],
    74.0: <String>['चौहत्तर'],
    75.0: <String>['पचहत्तर'],
    76.0: <String>['छिहत्तर'],
    77.0: <String>['सतहत्तर'],
    78.0: <String>['अठहत्तर'],
    79.0: <String>['उन्यासी'],
    80.0: <String>['अस्सी'],
    81.0: <String>['इक्यासी'],
    82.0: <String>['बयासी'],
    83.0: <String>['तिरासी'],
    84.0: <String>['चौरासी'],
    85.0: <String>['पचासी'],
    86.0: <String>['छियासी'],
    87.0: <String>['सत्तासी'],
    88.0: <String>['अट्ठासी'],
    89.0: <String>['नवासी'],
    90.0: <String>['नब्बे'],
    91.0: <String>['इक्यानवे'],
    92.0: <String>['बानवे'],
    93.0: <String>['तिरानवे'],
    94.0: <String>['चौरानवे'],
    95.0: <String>['पचानवे'],
    96.0: <String>['छियानवे'],
    97.0: <String>['सत्तानवे'],
    98.0: <String>['अट्ठानवे'],
    99.0: <String>['निन्यानवे'],
  });

  // Hindi fractions: ढाई = 2½, डेढ़ = 1½
  static final Map<String, double> _n4 = _table(<double, List<String>>{
    1.5: <String>['डेढ़', 'डेढ'],
    2.5: <String>['ढाई'],
  });

  // Urdu
  static final Map<String, double> _n5 = _table(<double, List<String>>{
    1.0: <String>['ایک'],
    2.0: <String>['دو'],
    3.0: <String>['تین'],
    4.0: <String>['چار'],
    5.0: <String>['پانچ'],
    6.0: <String>['چھ'],
    7.0: <String>['سات'],
    8.0: <String>['آٹھ'],
    9.0: <String>['نو'],
    10.0: <String>['دس'],
    11.0: <String>['گیارہ'],
    12.0: <String>['بارہ'],
    13.0: <String>['تیرہ'],
    14.0: <String>['چودہ'],
    15.0: <String>['پندرہ'],
    16.0: <String>['سولہ'],
    17.0: <String>['سترہ'],
    18.0: <String>['اٹھارہ'],
    19.0: <String>['انیس'],
    20.0: <String>['بیس'],
    21.0: <String>['اکیس'],
    22.0: <String>['بائیس'],
    23.0: <String>['تیئس'],
    24.0: <String>['چوبیس'],
    25.0: <String>['پچیس'],
    26.0: <String>['چھبیس'],
    27.0: <String>['ستائیس'],
    28.0: <String>['اٹھائیس'],
    29.0: <String>['انتیس'],
    30.0: <String>['تیس'],
    31.0: <String>['اکتیس'],
    32.0: <String>['بتیس'],
    33.0: <String>['تینتیس'],
    34.0: <String>['چونتیس'],
    35.0: <String>['پینتیس'],
    36.0: <String>['چھتیس'],
    37.0: <String>['سینتیس'],
    38.0: <String>['اڑتیس'],
    39.0: <String>['انتالیس'],
    40.0: <String>['چالیس'],
    41.0: <String>['اکتالیس'],
    42.0: <String>['بیالیس'],
    43.0: <String>['تینتالیس'],
    44.0: <String>['چوالیس'],
    45.0: <String>['پینتالیس'],
    46.0: <String>['چھیالیس'],
    47.0: <String>['سینتالیس'],
    48.0: <String>['اڑتالیس'],
    49.0: <String>['انچاس'],
    50.0: <String>['پچاس'],
    51.0: <String>['اکاون'],
    52.0: <String>['باون'],
    53.0: <String>['ترپن'],
    54.0: <String>['چون'],
    55.0: <String>['پچپن'],
    56.0: <String>['چھپن'],
    57.0: <String>['ستاون'],
    58.0: <String>['اٹھاون'],
    59.0: <String>['انسٹھ'],
    60.0: <String>['ساٹھ'],
    61.0: <String>['اکسٹھ'],
    62.0: <String>['باسٹھ'],
    63.0: <String>['ترسٹھ'],
    64.0: <String>['چونسٹھ'],
    65.0: <String>['پینسٹھ'],
    66.0: <String>['چھیاسٹھ'],
    67.0: <String>['سڑسٹھ'],
    68.0: <String>['اڑسٹھ'],
    69.0: <String>['انہتر'],
    70.0: <String>['ستر'],
    71.0: <String>['اکہتر'],
    72.0: <String>['بہتر'],
    73.0: <String>['تہتر'],
    74.0: <String>['چوہتر'],
    75.0: <String>['پچہتر'],
    76.0: <String>['چھہتر'],
    77.0: <String>['ستتر'],
    78.0: <String>['اٹھہتر'],
    79.0: <String>['اناسی'],
    80.0: <String>['اسی'],
    81.0: <String>['اکیاسی'],
    82.0: <String>['بیاسی'],
    83.0: <String>['تراسی'],
    84.0: <String>['چوراسی'],
    85.0: <String>['پچاسی'],
    86.0: <String>['چھیاسی'],
    87.0: <String>['ستاسی'],
    88.0: <String>['اٹھاسی'],
    89.0: <String>['نواسی'],
    90.0: <String>['نوے'],
    91.0: <String>['اکانوے'],
    92.0: <String>['بانوے'],
    93.0: <String>['ترانوے'],
    94.0: <String>['چورانوے'],
    95.0: <String>['پچانوے'],
    96.0: <String>['چھیانوے'],
    97.0: <String>['ستانوے'],
    98.0: <String>['اٹھانوے'],
    99.0: <String>['ننانوے'],
  });

  // Urdu fractions
  static final Map<String, double> _n6 = _table(<double, List<String>>{
    1.5: <String>['ڈیڑھ', 'ڈیڑہ'],
    2.5: <String>['ڈھائی'],
  });

  // Persian
  static final Map<String, double> _n7 = _table(<double, List<String>>{
    1.0: <String>['یک'],
    2.0: <String>['دو'],
    3.0: <String>['سه'],
    4.0: <String>['چهار'],
    5.0: <String>['پنج'],
    6.0: <String>['شش'],
    7.0: <String>['هفت'],
    8.0: <String>['هشت'],
    9.0: <String>['نه'],
    10.0: <String>['ده'],
    11.0: <String>['یازده'],
    12.0: <String>['دوازده'],
    13.0: <String>['سیزده'],
    14.0: <String>['چهارده'],
    15.0: <String>['پانزده'],
    16.0: <String>['شانزده'],
    17.0: <String>['هفده'],
    18.0: <String>['هجده', 'هیجده'],
    19.0: <String>['نوزده'],
    20.0: <String>['بیست'],
    30.0: <String>['سی'],
    40.0: <String>['چهل'],
    50.0: <String>['پنجاه'],
    60.0: <String>['شصت'],
    70.0: <String>['هفتاد'],
    80.0: <String>['هشتاد'],
    90.0: <String>['نود'],
    100.0: <String>['صد', 'یکصد'],
    200.0: <String>['دویست'],
    300.0: <String>['سیصد'],
    400.0: <String>['چهارصد'],
    500.0: <String>['پانصد'],
    600.0: <String>['ششصد'],
    700.0: <String>['هفتصد'],
    800.0: <String>['هشتصد'],
    900.0: <String>['نهصد'],
  });

  // Turkish
  static final Map<String, double> _n8 = _table(<double, List<String>>{
    1.0: <String>['bir'],
    2.0: <String>['iki'],
    3.0: <String>['üç'],
    4.0: <String>['dört'],
    5.0: <String>['beş'],
    6.0: <String>['altı'],
    7.0: <String>['yedi'],
    8.0: <String>['sekiz'],
    9.0: <String>['dokuz'],
    10.0: <String>['on'],
    20.0: <String>['yirmi'],
    30.0: <String>['otuz'],
    40.0: <String>['kırk'],
    50.0: <String>['elli'],
    60.0: <String>['altmış'],
    70.0: <String>['yetmiş'],
    80.0: <String>['seksen'],
    90.0: <String>['doksan'],
  });

  // Indonesian and Malay
  static final Map<String, double> _n9 = _table(<double, List<String>>{
    1.0: <String>['satu'],
    2.0: <String>['dua'],
    3.0: <String>['tiga'],
    4.0: <String>['empat'],
    5.0: <String>['lima'],
    6.0: <String>['enam'],
    7.0: <String>['tujuh'],
    8.0: <String>['delapan', 'lapan'],
    9.0: <String>['sembilan'],
    10.0: <String>['sepuluh'],
    11.0: <String>['sebelas'],
    100.0: <String>['seratus'],
  });

  // Hindi and Urdu: साढ़े / ساڑھے (+½), सवा / سوا (+¼), पौने / پونے (−¼) the next number
  static final Map<String, double> _adjusts = _table(<double, List<String>>{
    0.5: <String>['साढ़े', 'साढे', 'ساڑھے', 'ساڑھے'],
    0.25: <String>['सवा', 'سوا'],
    -0.25: <String>['पौने', 'پونے'],
  });

  // Thousands and above
  static final Map<String, double> _scales = _table(<double, List<String>>{
    1000.0: <String>['ألف', 'آلاف', 'ألاف', 'تلاف', 'تالاف', 'thousand', 'thousands', 'mille', 'milles', 'हज़ार', 'हजार', 'ہزار', 'هزار', 'bin', 'ribu', 'rb'],
    100000.0: <String>['लाख', 'لاکھ'],
    1000000.0: <String>['مليون', 'ملايين', 'million', 'millions', 'मिलियन', 'ملین', 'میلیون', 'milyon', 'juta'],
    10000000.0: <String>['करोड़', 'करोड', 'کروڑ'],
    1000000000.0: <String>['مليار', 'مليارات', 'billion', 'billions', 'milliard', 'milliards', 'میلیارد', 'milyar', 'miliar', 'bilion'],
  });

  // A number and its scale in one word
  static final Map<String, double> _duals = _table(<double, List<String>>{
    2000.0: <String>['ألفين', 'ألفان'],
    2000000.0: <String>['مليونين', 'مليونان'],
    1000.0: <String>['seribu'],
    1000000.0: <String>['sejuta'],
  });

  static final Set<String> _hundreds = _set(<String>['مائة', 'مئة', 'مية', 'ميه', 'مايه', 'ميت', 'hundred', 'hundreds', 'cent', 'cents', 'सौ', 'سو', 'yüz', 'ratus']);
  static final Set<String> _halves = _set(<String>['نص', 'نصف']);
  static final Set<String> _quarters = _set(<String>['ربع']);
  // Indonesian and Malay: «dua puluh» = 2 × 10, «dua belas» = 2 + 10.
  static final Set<String> _tens = _set(<String>['puluh']);
  static final Set<String> _teens = _set(<String>['belas']);
  static final Set<String> _connectors = _set(<String>['و', 'and', 'et']);
  // Words that are something else when said alone: Turkish «on» (10) is
  // English «on», «bin» (1000) is part of Malay names («Ahmad bin Ali»),
  // Persian «نه» (9) is «no».
  static final Set<String> _notAlone = _set(<String>['on', 'bin', 'نه', 'se', 'rb']);
  static final Map<String, double> _numbers = <String, double>{
    ..._n0,
    ..._n1,
    ..._n2,
    ..._n3,
    ..._n4,
    ..._n5,
    ..._n6,
    ..._n7,
    ..._n8,
    ..._n9,
  };
}

enum _Kind { number, adjust, hundred, tens, teen, scale, dual, half, quarter }

class _Part {
  const _Part(this.kind, this.value, this.word);
  final _Kind kind;
  final double value;
  final String word;
}
