import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/time/date_input.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

void main() {
  group('DateInput.parse', () {
    test('year/month/day', () {
      expect(DateInput.parse('2026/10/25'), DateTime(2026, 10, 25));
      expect(DateInput.parse('  2026/10/25 '), DateTime(2026, 10, 25));
      expect(DateInput.parse('2026 / 10 / 25'), DateTime(2026, 10, 25));
      expect(DateInput.parse('2026/1/5'), DateTime(2026, 1, 5));
      expect(DateInput.parse('2026-10-25'), DateTime(2026, 10, 25));
      expect(DateInput.parse('2026.10.25'), DateTime(2026, 10, 25));
    });

    test('a calendar day at local midnight, never UTC', () {
      final DateTime d = DateInput.parse('2026/10/25')!;
      expect(d.isUtc, isFalse);
      expect(<int>[d.hour, d.minute, d.second], <int>[0, 0, 0]);
    });

    test('impossible dates are refused', () {
      for (final String s in <String>[
        '2026/02/30',
        '2026/02/29', // 2026 is not a leap year
        '2100/02/29', // nor is 2100
        '2026/13/01',
        '2026/00/10',
        '2026/10/00',
        '2026/10/32',
        '2026/04/31',
      ]) {
        expect(DateInput.parse(s), isNull, reason: s);
      }
    });

    test('leap years and month boundaries', () {
      expect(DateInput.parse('2024/02/29'), DateTime(2024, 2, 29));
      expect(DateInput.parse('2000/02/29'), DateTime(2000, 2, 29));
      expect(DateInput.parse('2026/01/31'), DateTime(2026, 1, 31));
      expect(DateInput.parse('2026/12/31'), DateTime(2026, 12, 31));
      expect(DateInput.parse('2027/01/01'), DateTime(2027, 1, 1));
      expect(DateInput.parse('2026/04/30'), DateTime(2026, 4, 30));
    });

    test('half-typed, empty and other text', () {
      for (final String? s in <String?>[
        null,
        '',
        '   ',
        '2026',
        '2026/10',
        '2026/10/',
        '26/10/25',
        '2026/10-25', // mixed separators
        '2026/10/25/1',
        'abcd/ef/gh',
        '2026/10/25 12:00',
      ]) {
        expect(DateInput.parse(s), isNull, reason: s);
      }
    });

    test('Arabic, Persian, Devanagari and full-width digits', () {
      expect(DateInput.parse('٢٠٢٦/١٠/٢٥'), DateTime(2026, 10, 25));
      expect(DateInput.parse('۲۰۲۶/۱۰/۲۵'), DateTime(2026, 10, 25));
      expect(DateInput.parse('२०२६/१०/२५'), DateTime(2026, 10, 25));
      expect(DateInput.parse('２０２６／１０／２５'), DateTime(2026, 10, 25));
      expect(DateInput.parse('٢٠٢٦/٠٢/٣٠'), isNull);
    });

    test('invisible direction marks from right-to-left text', () {
      for (final String s in <String>[
        '\u200f2026/10/25',
        '2026\u200f/10\u200f/25',
        '\u202b2026/10/25\u202c',
        '\u20662026/10/25\u2069',
        '\u200e2026/\u200e10/\u200e25\u200e',
        '\u061c2026/10/25',
        '\ufeff2026/10/25',
        '2026\u200b/10/25',
      ]) {
        expect(DateInput.parse(s), DateTime(2026, 10, 25),
            reason: s.codeUnits.toString());
      }
    });

    test('format writes what parse reads', () {
      for (final DateTime d in <DateTime>[
        DateTime(2026, 10, 25),
        DateTime(2024, 2, 29),
        DateTime(2026, 1, 1),
        DateTime(2026, 12, 31),
      ]) {
        expect(DateInput.format(d), matches(RegExp(r'^\d{4}/\d{2}/\d{2}$')));
        expect(DateInput.parse(DateInput.format(d)), d);
      }
      expect(DateInput.format(DateTime(2026, 3, 5)), '2026/03/05');
    });
  });

  group('stored transactions keep their calendar day', () {
    Transaction txn(DateTime date) => Transaction(
          id: 't1',
          date: date,
          type: TransactionType.expense,
          category: 'الطعام',
          amount: const Money(1500, 'USD'),
          createdAt: DateTime(2026, 10, 25, 9),
        );

    test('save and reload, near midnight too', () {
      for (final DateTime d in <DateTime>[
        DateInput.parse('2026/10/25')!,
        DateTime(2026, 10, 25, 23, 59, 59),
        DateTime(2026, 10, 25, 0, 0, 1),
        DateTime(2026, 12, 31, 23, 30),
        DateTime(2024, 2, 29, 23, 59),
      ]) {
        final Map<String, dynamic> json = txn(d).toJson();
        // Local wall time, no "Z": reading it back in any time zone gives
        // the same day.
        expect(json['date'], isNot(endsWith('Z')));
        final DateTime back = Transaction.fromJson(json).date;
        expect(<int>[back.year, back.month, back.day],
            <int>[d.year, d.month, d.day]);
      }
    });

    test('records saved by earlier versions still load', () {
      final Map<String, dynamic> json = txn(DateTime(2026, 10, 25)).toJson();
      for (final String old in <String>[
        '2026-10-25T00:00:00.000',
        '2026-10-25T14:03:12.345678',
        '2026-10-25',
      ]) {
        final DateTime d =
            Transaction.fromJson(<String, dynamic>{...json, 'date': old}).date;
        expect(<int>[d.year, d.month, d.day], <int>[2026, 10, 25], reason: old);
      }
    });

    test('sorting by date is unchanged', () {
      final List<DateTime> days = <String>[
        '2026/10/25',
        '2024/02/29',
        '2026/01/01'
      ].map((String s) => DateInput.parse(s)!).toList()
        ..sort();
      expect(days, <DateTime>[
        DateTime(2024, 2, 29),
        DateTime(2026, 1, 1),
        DateTime(2026, 10, 25),
      ]);
    });
  });

  test('a scanned receipt never gets an impossible day', () {
    DateTime? date(String s) =>
        ScannedReceipt.fromCloudJson(<String, dynamic>{'date': s}).date;
    expect(date('2026-10-25'), DateTime(2026, 10, 25));
    expect(date('2026-02-30'), isNull); // was read as 2 March
    expect(date('2026-10-25T10:00:00'), DateTime(2026, 10, 25, 10));
  });
}
