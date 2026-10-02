// 80 invoices (8 kinds × 10) run through the invoice reader's checking stage:
// what the model returns (amounts copied as printed, in many formats and
// languages) → InvoiceAnalyzer → compared with the known true values.
//
// The model's reading of the photo itself is not exercised here (that needs
// the live service); everything after it is: number formats, items, totals,
// arithmetic checks, confidence and review level.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';

final DateTime today = DateTime(2026, 10, 2);

enum Style { dotComma, spaceComma, dotThousandsComma, plainDot, plainComma, arabicIndic }

/// [minor] (hundredths) printed in [s].
String fmt(int minor, Style s) {
  final bool neg = minor < 0;
  final int a = minor.abs();
  final String units = (a ~/ 100).toString();
  final String cents = (a % 100).toString().padLeft(2, '0');
  String group(String sep) {
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < units.length; i++) {
      if (i > 0 && (units.length - i) % 3 == 0) b.write(sep);
      b.write(units[i]);
    }
    return b.toString();
  }

  // Whole amounts of a thousand or more are often printed without decimals
  // ("1.250" / "1,250"): ambiguous on their own, settled by the invoice.
  final bool bare = a % 100 == 0 && a >= 100000;
  if (bare && (s == Style.dotThousandsComma || s == Style.dotComma)) {
    final String g = group(s == Style.dotComma ? ',' : '.');
    return neg ? '-$g' : g;
  }
  final String out = switch (s) {
    Style.dotComma => '${group(',')}.$cents',
    Style.spaceComma => '${group(' ')},$cents',
    Style.dotThousandsComma => '${group('.')},$cents',
    Style.plainDot => '$units.$cents',
    Style.plainComma => '$units,$cents',
    Style.arabicIndic => _arabic('${group('٬')}٫$cents'),
  };
  return neg ? '-$out' : out;
}

String _arabic(String s) {
  const String d = '٠١٢٣٤٥٦٧٨٩';
  return s.replaceAllMapped(RegExp(r'\d'), (Match m) => d[int.parse(m[0]!)]);
}

String fmtQty(double q, Style s) {
  if (q == q.roundToDouble()) {
    final String v = q.toStringAsFixed(0);
    return s == Style.arabicIndic ? _arabic(v) : v;
  }
  final String v = q.toStringAsFixed(3);
  final bool comma = s == Style.spaceComma ||
      s == Style.dotThousandsComma ||
      s == Style.plainComma;
  if (s == Style.arabicIndic) return _arabic(v.replaceAll('.', '٫'));
  return comma ? v.replaceAll('.', ',') : v;
}

class Line {
  Line(this.name, this.q, this.u, this.t, {this.c = 0.95, this.alt});
  final String name;
  final double? q;
  final int? u; // minor units
  final int t; // minor units
  final double c;
  final String? alt; // a translation line printed under it
}

class Case {
  Case({
    required this.label,
    required this.lines,
    required this.style,
    this.inv,
    this.date,
    this.cur,
    this.sym,
    this.sup,
    this.sub,
    this.dis,
    this.tax,
    this.tot,
    this.expectLevel = ReviewLevel.verified,
    this.expectIssues = const <InvoiceIssue>{},
    this.expectTotal,
    this.expectCurrency,
    this.printQuantities = true,
    this.overrides = const <int, Map<String, String>>{},
    this.summaryText = const <String, String>{},
  });
  final String label;
  final List<Line> lines;
  final Style style;
  final String? inv;
  final DateTime? date;
  final String? cur;
  final String? sym;
  final String? sup;
  final int? sub;
  final int? dis;
  final int? tax;
  final int? tot;
  final ReviewLevel expectLevel;
  final Set<InvoiceIssue> expectIssues;
  final int? expectTotal;
  final String? expectCurrency;
  final bool printQuantities;

  /// Item index → field → printed text, to inject reading faults.
  final Map<int, Map<String, String>> overrides;

  /// Summary key (sub, tot…) → printed text, replacing the generated one.
  final Map<String, String> summaryText;

  Map<String, dynamic> raw() {
    String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final List<Map<String, dynamic>> it = <Map<String, dynamic>>[];
    for (int i = 0; i < lines.length; i++) {
      final Line l = lines[i];
      it.add(<String, dynamic>{
        'n': l.name,
        'q': printQuantities && l.q != null ? fmtQty(l.q!, style) : '',
        'u': l.u == null ? '' : fmt(l.u!, style),
        't': fmt(l.t, style),
        'c': l.c,
        ...?overrides[i],
      });
      if (l.alt != null) {
        it.add(<String, dynamic>{'n': l.alt, 'q': '', 'u': '', 't': '', 'c': 0.9});
      }
    }
    return <String, dynamic>{
      'r': true,
      'inv': inv ?? '',
      'dt': date == null ? '' : ymd(date!),
      'cur': cur ?? '',
      'sym': sym ?? '',
      'sup': sup ?? '',
      'cus': '',
      'cat': 'التسوق',
      'it': it,
      'sub': sub == null ? '' : fmt(sub!, style),
      'dis': dis == null ? '' : fmt(dis!, style),
      'tax': tax == null ? '' : fmt(tax!, style),
      'tot': tot == null ? '' : fmt(tot!, style),
      'paid': '',
      'due': '',
      ...summaryText,
    };
  }
}

// ---- generators ----

const List<String> enNames = <String>[
  'Milk 1L', 'Bread', 'Eggs x12', 'Coffee 250g', 'Rice 1kg', 'Apples',
  'Chicken breast', 'Olive oil 1L', 'Pasta 500g', 'Tomatoes', 'Cheese',
  'Yogurt', 'Orange juice', 'Butter', 'Sugar 1kg', 'Tea', 'Water 6x1.5L',
];
const List<String> frNames = <String>[
  'Lait 1L', 'Baguette', 'Œufs x12', 'Café moulu', 'Riz 1kg', 'Pommes',
  'Blanc de poulet', 'Huile d\'olive', 'Pâtes 500g', 'Tomates', 'Fromage',
  'Yaourt nature', 'Jus d\'orange', 'Beurre doux', 'Sucre 1kg',
];
const List<String> arNames = <String>[
  'حليب 1 لتر', 'خبز', 'بيض 12', 'قهوة 250غ', 'أرز 1كغ', 'تفاح', 'دجاج',
  'زيت زيتون', 'معكرونة', 'طماطم', 'جبن', 'زبادي', 'عصير برتقال', 'زبدة',
];

List<Line> makeLines(Random r, int n, List<String> names,
    {bool weights = false, String? Function(int i)? alt, int maxUnit = 2500}) {
  return <Line>[
    for (int i = 0; i < n; i++)
      () {
        final bool weighed = weights && i % 4 == 3;
        final double q =
            weighed ? (250 + r.nextInt(1750)) / 1000 : (1 + r.nextInt(4)).toDouble();
        final int u = 50 + r.nextInt(maxUnit);
        final int t = (q * u).round();
        return Line('${names[i % names.length]}${i >= names.length ? ' ${i ~/ names.length + 1}' : ''}',
            q, u, t, alt: alt?.call(i));
      }(),
  ];
}

int sumOf(List<Line> l) => l.fold<int>(0, (int a, Line b) => a + b.t);

DateTime dateFor(Random r) =>
    today.subtract(Duration(days: r.nextInt(300)));

List<Case> buildCases() {
  final List<Case> out = <Case>[];

  // 1. Simple: a few items, tax added on top.
  for (int k = 0; k < 10; k++) {
    final Random r = Random(100 + k);
    final List<Line> lines = makeLines(r, 2 + r.nextInt(3), enNames);
    final int sub = sumOf(lines);
    final int tax = (sub * 0.08).round();
    out.add(Case(
      label: 'simple #$k',
      lines: lines,
      style: Style.dotComma,
      inv: 'INV-${1000 + k}',
      date: dateFor(r),
      cur: 'USD',
      sym: 'US\$',
      sup: 'Corner Shop',
      sub: sub,
      tax: tax,
      tot: sub + tax,
    ));
  }

  // 2. Supermarket: many items, weights, a discount line, VAT included.
  for (int k = 0; k < 10; k++) {
    final Random r = Random(200 + k);
    final List<Line> lines = <Line>[
      ...makeLines(r, 15 + r.nextInt(16), frNames, weights: true),
      Line('Remise fidélité', null, null, -(50 + r.nextInt(300))),
    ];
    final int sub = sumOf(lines);
    out.add(Case(
      label: 'supermarket #$k',
      lines: lines,
      style: Style.spaceComma,
      inv: 'T${50000 + k}',
      date: dateFor(r),
      cur: 'EUR',
      sym: '€',
      sup: 'SuperMarché',
      sub: sub,
      // "dont TVA": tax already inside the total.
      tax: (sub * 0.055).round(),
      tot: sub,
    ));
  }

  // 3. Long: 50 to 100 items, Algerian dinars.
  for (int k = 0; k < 10; k++) {
    final Random r = Random(300 + k);
    final List<Line> lines =
        makeLines(r, 50 + r.nextInt(51), frNames, maxUnit: 90000);
    final int sub = sumOf(lines);
    out.add(Case(
      label: 'long #$k',
      lines: lines,
      style: Style.spaceComma,
      inv: 'FA-2026-${k.toString().padLeft(4, '0')}',
      date: dateFor(r),
      cur: 'DZD',
      sym: 'DA',
      sup: 'Hypermarché Ardis',
      sub: sub,
      tot: sub,
    ));
  }

  // 4. French: HT + TVA = TTC, with a discount.
  for (int k = 0; k < 10; k++) {
    final Random r = Random(400 + k);
    final List<Line> lines = <Line>[
      ...makeLines(r, 5 + r.nextInt(8), frNames),
      Line('Carte cadeau', 1, 125000, 125000),
    ];
    final int sub = sumOf(lines);
    final int dis = (sub * 0.05).round();
    final int tax = ((sub - dis) * 0.20).round();
    out.add(Case(
      label: 'french #$k',
      lines: lines,
      style: k.isEven ? Style.spaceComma : Style.dotThousandsComma,
      inv: 'F${2026000 + k}',
      date: dateFor(r),
      cur: 'EUR',
      sym: 'EUR',
      sup: 'Boulangerie Martin',
      sub: sub,
      dis: dis,
      tax: tax,
      tot: sub - dis + tax,
    ));
  }

  // 5. English: dollars and pounds, tax added.
  const List<(String, String)> curs = <(String, String)>[
    ('USD', r'$'), ('GBP', '£'), ('CAD', r'C$'), ('USD', 'USD'), ('GBP', 'GBP'),
  ];
  for (int k = 0; k < 10; k++) {
    final Random r = Random(500 + k);
    final List<Line> lines = <Line>[
      ...makeLines(r, 3 + r.nextInt(10), enNames, maxUnit: 400000),
      Line('Gift card', 2, 125000, 250000),
    ];
    final int sub = sumOf(lines);
    final int tax = (sub * 0.2).round();
    final (String, String) c = curs[k % curs.length];
    out.add(Case(
      label: 'english #$k',
      lines: lines,
      style: k.isEven ? Style.dotComma : Style.plainDot,
      inv: 'GM-2026-00${4500 + k}',
      date: dateFor(r),
      cur: c.$1,
      sym: c.$2,
      sup: 'GlobalMart',
      sub: sub,
      tax: tax,
      tot: sub + tax,
      // "$" alone fits several dollars: worth a glance, not a block.
      expectLevel: c.$2 == r'$' ? ReviewLevel.warning : ReviewLevel.verified,
    ));
  }

  // 6. Arabic: Arabic-Indic digits, VAT 15%, names repeated in English.
  const List<(String, String)> arCurs = <(String, String)>[
    ('SAR', 'ر.س'), ('AED', 'د.إ'),
  ];
  for (int k = 0; k < 10; k++) {
    final Random r = Random(600 + k);
    final List<Line> lines = makeLines(r, 3 + r.nextInt(8), arNames,
        alt: (int i) => i.isEven ? enNames[i % enNames.length] : null);
    final int sub = sumOf(lines);
    final int tax = (sub * 0.15).round();
    final (String, String) c = arCurs[k % 2];
    out.add(Case(
      label: 'arabic #$k',
      lines: lines,
      style: k.isEven ? Style.arabicIndic : Style.dotComma,
      inv: '${7000 + k}',
      date: dateFor(r),
      cur: c.$1,
      sym: c.$2,
      sup: 'أسواق العثيم',
      sub: sub,
      tax: tax,
      tot: sub + tax,
    ));
  }

  // 7. Mixed: Arabic + French (+ English), dinars "DA".
  for (int k = 0; k < 10; k++) {
    final Random r = Random(700 + k);
    final List<Line> lines = <Line>[
      ...makeLines(r, 4 + r.nextInt(10), arNames,
          maxUnit: 50000, alt: (int i) => frNames[i % frNames.length]),
      Line('قارورة غاز Bouteille de gaz', 1, 100000, 100000),
    ];
    final int sub = sumOf(lines);
    out.add(Case(
      label: 'mixed #$k',
      lines: lines,
      style: <Style>[Style.spaceComma, Style.plainComma, Style.dotThousandsComma][k % 3],
      inv: k.isEven ? 'B-$k${2026}' : null,
      date: dateFor(r),
      cur: 'DZD',
      sym: k.isEven ? 'DA' : 'د.ج',
      sup: 'Supérette El Baraka',
      sub: sub,
      tot: sub,
      // No invoice number on odd receipts: still verified.
    ));
  }

  // 8. Low quality: missing values, faint lines, misread figures.
  for (int k = 0; k < 10; k++) {
    final Random r = Random(800 + k);
    final List<Line> lines = makeLines(r, 4 + r.nextInt(6), enNames);
    final int sub = sumOf(lines);
    final int tax = (sub * 0.1).round();
    switch (k) {
      case 0: // a misread line total: must be flagged, never corrected
        out.add(Case(
          label: 'low #0 misread line total',
          lines: lines,
          style: Style.dotComma,
          inv: 'X1', date: dateFor(r), cur: 'USD', sym: 'USD',
          sub: sub, tax: tax, tot: sub + tax,
          overrides: <int, Map<String, String>>{
            1: <String, String>{'t': fmt(lines[1].t + 500, Style.dotComma)},
          },
          expectLevel: ReviewLevel.review,
          expectIssues: <InvoiceIssue>{
            InvoiceIssue.lineMismatch,
            InvoiceIssue.itemsVsSubtotal,
          },
        ));
      case 1: // no total printed: calculated and flagged
        out.add(Case(
          label: 'low #1 no total',
          lines: lines, style: Style.dotComma,
          date: dateFor(r), cur: 'USD', sym: 'USD',
          sub: sub, tax: tax,
          expectTotal: sub + tax,
          expectLevel: ReviewLevel.review,
          expectIssues: <InvoiceIssue>{InvoiceIssue.totalComputed},
        ));
      case 2: // faded receipt: quantities and unit prices unreadable
        out.add(Case(
          label: 'low #2 totals only',
          lines: lines, style: Style.spaceComma, printQuantities: false,
          date: dateFor(r), cur: 'EUR', sym: '€',
          sub: sub, tot: sub,
          overrides: <int, Map<String, String>>{
            for (int i = 0; i < lines.length; i++) i: <String, String>{'u': ''},
          },
        ));
      case 3: // a very faint line
        out.add(Case(
          label: 'low #3 faint line',
          lines: <Line>[
            ...lines.take(lines.length - 1),
            Line(lines.last.name, lines.last.q, lines.last.u, lines.last.t, c: 0.3),
          ],
          style: Style.dotComma, date: dateFor(r), cur: 'USD', sym: 'USD',
          sub: sub, tot: sub,
          expectLevel: ReviewLevel.review,
        ));
      case 4: // no currency anywhere
        out.add(Case(
          label: 'low #4 no currency',
          lines: lines, style: Style.dotComma, date: dateFor(r),
          sub: sub, tot: sub,
          expectLevel: ReviewLevel.warning,
          expectIssues: <InvoiceIssue>{InvoiceIssue.currencyUnknown},
        ));
      case 5: // no date
        out.add(Case(
          label: 'low #5 no date',
          lines: lines, style: Style.dotComma, cur: 'USD', sym: 'USD',
          sub: sub, tot: sub,
          expectLevel: ReviewLevel.warning,
          expectIssues: <InvoiceIssue>{InvoiceIssue.dateMissing},
        ));
      case 6: // a misread total
        out.add(Case(
          label: 'low #6 misread total',
          lines: lines, style: Style.dotComma, date: dateFor(r),
          cur: 'USD', sym: 'USD', sub: sub, tax: tax, tot: sub + tax + 900,
          expectLevel: ReviewLevel.review,
          expectIssues: <InvoiceIssue>{InvoiceIssue.summaryMismatch},
        ));
      case 7: // "1.250" style unit prices in a 3-decimal currency (TND)
        final List<Line> tnd = <Line>[
          Line('Pain', 2, 1250, 2500),
          Line('Lait', 3, 1450, 4350),
        ];
        out.add(Case(
          label: 'low #7 ambiguous 3-decimal amounts',
          lines: tnd, style: Style.dotComma, date: dateFor(r),
          cur: 'TND', sym: 'DT', sub: 6850, tot: 6850,
          summaryText: <String, String>{'sub': '6.850', 'tot': '6.850'},
          overrides: <int, Map<String, String>>{
            0: <String, String>{'u': '1.250', 't': '2.500'},
            1: <String, String>{'u': '1.450', 't': '4.350'},
          },
        ));
      case 8: // sign and code disagree
        out.add(Case(
          label: 'low #8 currency conflict',
          lines: lines, style: Style.dotComma, date: dateFor(r),
          cur: 'USD', sym: '€', sub: sub, tot: sub,
          expectCurrency: 'EUR',
          expectLevel: ReviewLevel.warning,
          expectIssues: <InvoiceIssue>{InvoiceIssue.currencyConflict},
        ));
      default: // date in the future (misread year)
        out.add(Case(
          label: 'low #9 future date',
          lines: lines, style: Style.dotComma,
          date: DateTime(2029, 3, 1), cur: 'USD', sym: 'USD',
          sub: sub, tot: sub,
          expectLevel: ReviewLevel.warning,
          expectIssues: <InvoiceIssue>{InvoiceIssue.dateSuspicious},
        ));
    }
  }
  return out;
}

void main() {
  final List<Case> cases = buildCases();

  test('80 invoices are generated', () {
    expect(cases.length, 80);
  });

  for (final Case c in cases) {
    test(c.label, () {
      final InvoiceReading r = InvoiceAnalyzer.analyze(c.raw(), today: today);
      final bool totalsOnly = c.label.contains('totals only');
      final bool tnd = c.label.contains('3-decimal');
      double money(int minor) => tnd ? minor / 1000 : minor / 100;

      // Header.
      expect(r.invoiceNumber, c.inv, reason: 'invoice number');
      if (c.date != null) {
        expect(r.date, DateTime(c.date!.year, c.date!.month, c.date!.day));
      } else {
        expect(r.date, isNull);
      }
      expect(r.currency, c.expectCurrency ?? c.cur, reason: 'currency');

      // Items: translation lines merged, every figure exact.
      expect(r.items.length, c.lines.length, reason: 'item count');
      for (int i = 0; i < c.lines.length; i++) {
        final Line l = c.lines[i];
        final InvoiceItem it = r.items[i];
        expect(it.name, l.name);
        final String? injectedT = c.overrides[i]?['t'];
        if (injectedT == null) {
          expect(it.lineTotal, closeTo(money(l.t), 1e-6), reason: 'line $i total');
        }
        if (!totalsOnly) {
          expect(it.quantity, l.q == null ? isNull : closeTo(l.q!, 1e-9),
              reason: 'line $i qty');
          if (l.u != null) {
            expect(it.unitPrice, closeTo(money(l.u!), 1e-6), reason: 'line $i unit');
          }
        } else {
          expect(it.quantity, isNull, reason: 'never assumes a quantity');
          expect(it.unitPrice, isNull);
        }
      }

      // Summary.
      if (c.sub != null) expect(r.subtotal, closeTo(money(c.sub!), 1e-6));
      if (c.dis != null) expect(r.discount, closeTo(money(c.dis!), 1e-6));
      if (c.tax != null) expect(r.tax, closeTo(money(c.tax!), 1e-6));
      final int? total = c.expectTotal ?? c.tot;
      expect(r.total, closeTo(money(total!), 1e-6), reason: 'total');

      // Checks and review level.
      for (final InvoiceIssue i in c.expectIssues) {
        expect(r.checks.issues, contains(i));
      }
      expect(r.level(), c.expectLevel, reason: 'issues: ${r.checks.issues}');
      if (c.expectLevel == ReviewLevel.verified) {
        expect(r.checks.hasErrors, isFalse);
      }
    });
  }

  test('JSON output has the documented shape', () {
    final InvoiceReading r = InvoiceAnalyzer.analyze(cases.first.raw(), today: today);
    final Map<String, Object?> j = r.toJson();
    for (final String k in <String>[
      'invoice_number', 'date', 'currency', 'supplier', 'items', 'subtotal',
      'discount', 'tax', 'total', 'validation', 'total_confidence',
    ]) {
      expect(j.containsKey(k), isTrue, reason: k);
    }
    final Map<String, Object?> v = j['validation']! as Map<String, Object?>;
    expect(v['items_sum_matches_subtotal'], isTrue);
    expect(v['total_matches_calculation'], isTrue);
    expect(v['has_errors'], isFalse);
  });

  test('a user correction clears the mismatch', () {
    final Case bad = cases.firstWhere((Case c) => c.label.startsWith('low #0'));
    final InvoiceReading r = InvoiceAnalyzer.analyze(bad.raw(), today: today);
    expect(r.level(), ReviewLevel.review);
    final List<InvoiceItem> fixed = <InvoiceItem>[...r.items];
    fixed[1] = fixed[1].copyWith(
        lineTotal: bad.lines[1].t / 100, editedByUser: true);
    final InvoiceReading again =
        InvoiceAnalyzer.revalidate(r, fixed, today: today);
    expect(again.checks.issues, isNot(contains(InvoiceIssue.lineMismatch)));
    expect(again.checks.itemsSumMatchesSubtotal, isTrue);
    expect(again.level(), ReviewLevel.verified);
  });
}
