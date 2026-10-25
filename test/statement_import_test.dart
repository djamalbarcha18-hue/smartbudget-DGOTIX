import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/statement_import/domain/statement_parser.dart';
import 'package:smartbudget/features/statement_import/domain/table_reader.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 25);

  StatementRead readCsv(String csv, {bool unsignedIncome = false}) {
    final SheetTable t = TableReader.read(Uint8List.fromList(utf8.encode(csv)));
    final g = StatementParser.guess(t);
    return StatementParser.read(t, g.header, g.columns,
        today: today, unsignedIncome: unsignedIncome);
  }

  group('reading the file', () {
    test('CSV: quotes, separators inside them, a semicolon file', () {
      expect(TableReader.csv('a,"b, c","say ""hi"""\n1,2,3\n'), <List<String>>[
        <String>['a', 'b, c', 'say "hi"'],
        <String>['1', '2', '3'],
      ]);
      expect(
          TableReader.csv('Date;Montant;Libellé\n24/10/2026;-12,50;CAFÉ\n')[1],
          <String>['24/10/2026', '-12,50', 'CAFÉ']);
      expect(TableReader.csv('a\tb\n1\t2\n')[1], <String>['1', '2']);
    });

    test('an Arabic CSV saved by Excel in the old Windows code page', () {
      // «التاريخ» in Windows-1256.
      final Uint8List b = Uint8List.fromList(<int>[
        0xC7, 0xE1, 0xCA, 0xC7, 0xD1, 0xED, 0xCE, //
      ]);
      expect(TableReader.decode(b, lang: 'ar'), 'التاريخ');
      expect(
          TableReader.decode(
              Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode('أ')])),
          'أ');
    });

    test('an old .xls workbook is told apart', () {
      expect(
          () => TableReader.read(
              Uint8List.fromList(<int>[0xD0, 0xCF, 0x11, 0xE0, 0, 0, 0, 0])),
          throwsA(isA<TableReadException>().having(
              (TableReadException e) => e.error,
              'error',
              TableError.oldExcel)));
    });

    test('an Excel workbook: text, numbers and dates', () {
      final SheetTable t = TableReader.read(_xlsx());
      expect(t.rows[0], <String>['Date', 'Description', 'Amount']);
      expect(t.rows[1], <String>['2026-10-24', 'CARREFOUR', '-120.5']);
      expect(t.isNumber(1, 2), isTrue);
      expect(t.isNumber(1, 1), isFalse);
      final g = StatementParser.guess(t);
      final StatementRead r =
          StatementParser.read(t, g.header, g.columns, today: today);
      expect(r.rows.length, 2);
      expect(r.rows[0].amount, 120.5);
      expect(r.rows[0].type, TransactionType.expense);
      expect(r.rows[0].date, DateTime(2026, 10, 24));
      expect(r.rows[0].category, 'الطعام');
      expect(r.rows[1].amount, 4200);
      expect(r.rows[1].type, TransactionType.income);
    });
  });

  group('reading a statement', () {
    test('a bank statement: a title above, money out and in apart', () {
      final StatementRead r = readCsv('''
My Bank — Account statement
Account,SA1234567890
Period,01/10/2026 - 24/10/2026

Transaction Date,Value Date,Description,Debit,Credit,Balance
01/10/2026,01/10/2026,Opening balance,,,"5,000.00"
03/10/2026,03/10/2026,SALARY ACME LTD,,"8,500.00","13,500.00"
14/10/2026,14/10/2026,POS 4411 CARREFOUR RIYADH,"1,240.75",,"12,259.25"
21/10/2026,21/10/2026,UBER TRIP,32.00,,"12,227.25"
''');
      expect(r.unreadable, 0);
      expect(r.rows.length, 3);
      expect(r.rows[0].type, TransactionType.income);
      expect(r.rows[0].amount, 8500);
      expect(r.rows[0].date, DateTime(2026, 10, 3));
      expect(r.rows[1].type, TransactionType.expense);
      expect(r.rows[1].amount, 1240.75);
      expect(r.rows[1].description, 'POS 4411 CARREFOUR RIYADH');
      expect(r.rows[1].category, 'الطعام');
      expect(r.rows[2].category, 'النقل');
    });

    test('Arabic headers: مدين / دائن', () {
      final StatementRead r = readCsv('''
التاريخ,البيان,مدين,دائن,الرصيد
2026-10-20,صيدلية النهدي,250.00,,1200.00
2026-10-22,تحويل وارد,,1000.00,2200.00
''');
      expect(r.rows.map((StatementRow x) => x.type), <TransactionType>[
        TransactionType.expense,
        TransactionType.income,
      ]);
      expect(r.rows[0].category, 'الصحة');
    });

    test('French: one signed amount, comma decimals, semicolons', () {
      final StatementRead r = readCsv('''
Date opération;Libellé;Montant;Solde
24/10/2026;PAIEMENT CB MONOPRIX;-45,90;1 234,56
23/10/2026;VIREMENT RECU SALAIRE;2 450,00;1 280,46
''');
      expect(r.signed, isTrue);
      expect(r.rows[0].amount, 45.9);
      expect(r.rows[0].type, TransactionType.expense);
      expect(r.rows[1].amount, 2450);
      expect(r.rows[1].type, TransactionType.income);
    });

    test('US dates, and amounts with no sign: the user says what they are', () {
      const String csv = '''
Posted Date,Payee,Amount
10/14/2026,STARBUCKS,5.75
10/02/2026,SHELL OIL,40.10
''';
      final StatementRead r = readCsv(csv);
      expect(r.signed, isFalse);
      expect(r.rows[0].date, DateTime(2026, 10, 14));
      expect(r.rows[1].date, DateTime(2026, 10, 2));
      expect(
          r.rows.every((StatementRow x) => x.type == TransactionType.expense),
          isTrue);
      expect(
          readCsv(csv, unsignedIncome: true)
              .rows
              .every((StatementRow x) => x.type == TransactionType.income),
          isTrue);
    });

    test('a type column: DR / CR', () {
      final StatementRead r = readCsv('''
Date,Narration,Amount,Dr/Cr
20-Oct-2026,NEFT ACME LTD,"25,000.00",CR
21-Oct-2026,AMAZON,"1,499.00",DR
''');
      expect(r.rows[0].type, TransactionType.income);
      expect(r.rows[0].date, DateTime(2026, 10, 20));
      expect(r.rows[1].type, TransactionType.expense);
    });

    test('no header row: what the cells hold', () {
      final StatementRead r = readCsv('''
2026-10-01,Groceries at LIDL,-23.40
2026-10-02,Coffee,-3.10
2026-10-05,Refund,15.00
''');
      expect(r.rows.length, 3);
      expect(r.rows[0].amount, 23.4);
      expect(r.rows[0].description, 'Groceries at LIDL');
      expect(r.rows[2].type, TransactionType.income);
    });

    test('a line that cannot be read is counted, not guessed', () {
      final StatementRead r = readCsv('''
Date,Description,Amount
2026-10-01,Coffee,-3.10
not a date,Tea,-2.00
''');
      expect(r.rows.length, 1);
      expect(r.unreadable, 1);
    });

    test("SmartBudget's own CSV comes back as it was, ids included", () {
      final List<Transaction> txns = <Transaction>[
        Transaction(
          id: 'tx-1',
          date: DateTime(2026, 10, 20),
          type: TransactionType.expense,
          category: 'المطاعم',
          amount: const Money(4550, 'SAR'),
          description: 'Lunch, with "team"',
          notes: 'line one',
          createdAt: DateTime(2026, 10, 20),
        ),
        Transaction(
          id: 'tx-2',
          date: DateTime(2026, 10, 1),
          type: TransactionType.income,
          category: 'راتب أساسي',
          amount: const Money(800000, 'SAR'),
          createdAt: DateTime(2026, 10, 1),
        ),
      ];
      final StatementRead r =
          readCsv('﻿${BackupCodec.transactionsToCsv(txns)}');
      expect(r.rows.length, 2);
      expect(r.rows[0].id, 'tx-1');
      expect(r.rows[0].category, 'المطاعم');
      expect(r.rows[0].amount, 45.5);
      expect(r.rows[0].description, 'Lunch, with "team"');
      expect(r.rows[0].notes, 'line one');
      expect(r.rows[0].currency, 'SAR');
      expect(r.rows[1].type, TransactionType.income);
      expect(r.rows[1].category, 'راتب أساسي');
    });

    test('the same file read twice gives the same ids', () {
      const String csv = 'Date,Description,Amount\n'
          '2026-10-01,Coffee,-3.10\n2026-10-01,Coffee,-3.10\n';
      final List<String> a =
          readCsv(csv).rows.map((StatementRow x) => x.id).toList();
      expect(a.toSet().length, 2); // two coffees, two transactions
      expect(readCsv(csv).rows.map((StatementRow x) => x.id), a);
    });

    test('rows already recorded: same day, kind and amount', () {
      final StatementRead r = readCsv('Date,Description,Amount\n'
          '2026-10-01,Coffee,-3.10\n2026-10-01,Coffee,-3.10\n'
          '2026-10-02,Taxi,-12.00\n');
      final Set<int> known =
          StatementParser.alreadyRecorded(r.rows, <Transaction>[
        Transaction(
          id: 'mine',
          date: DateTime(2026, 10, 1, 9),
          type: TransactionType.expense,
          category: 'المطاعم',
          amount: const Money(310, 'SAR'),
          createdAt: DateTime(2026, 10, 1),
        ),
      ]);
      expect(known, <int>{0}); // one coffee was entered, not the second
    });
  });
}

/// A small workbook as Excel writes it: shared strings, a number, and a date
/// (serial 46319 = 2026-10-24) in a date style.
Uint8List _xlsx() {
  const String ns =
      'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
  final Map<String, String> files = <String, String>{
    'xl/workbook.xml': '<workbook $ns><sheets>'
        '<sheet name="Statement" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="worksheet" Target="worksheets/sheet1.xml"/>'
            '</Relationships>',
    'xl/sharedStrings.xml': '<sst $ns>'
        '<si><t>Date</t></si><si><t>Description</t></si><si><t>Amount</t></si>'
        '<si><r><t>CARRE</t></r><r><t>FOUR</t></r></si><si><t>SALARY</t></si></sst>',
    'xl/styles.xml': '<styleSheet $ns><cellXfs count="2">'
        '<xf numFmtId="0"/><xf numFmtId="14"/></cellXfs></styleSheet>',
    'xl/worksheets/sheet1.xml': '<worksheet $ns><sheetData>'
        '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
        '<c r="C1" t="s"><v>2</v></c></row>'
        '<row r="2"><c r="A2" s="1"><v>46319</v></c><c r="B2" t="s"><v>3</v></c>'
        '<c r="C2"><v>-120.5</v></c></row>'
        '<row r="3"><c r="A3" s="1"><v>46320</v></c><c r="B3" t="s"><v>4</v></c>'
        '<c r="C3"><v>4200</v></c></row>'
        '</sheetData></worksheet>',
  };
  final Archive a = Archive();
  files.forEach((String name, String xml) {
    final List<int> bytes = utf8.encode(xml);
    a.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(a));
}
