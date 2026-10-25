import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/time/date_input.dart';
import 'package:smartbudget/features/quick_entry/domain/bank_message.dart';
import 'package:smartbudget/features/quick_entry/domain/quick_entry_parser.dart';
import 'package:smartbudget/features/statement_import/domain/table_reader.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// What a column of a statement holds.
enum ImportField {
  date,
  description,

  /// One signed (or typed) amount per row.
  amount,

  /// Money out, when the statement splits it from money in.
  debit,

  /// Money in.
  credit,

  /// «Debit/Credit», «income/expense», «DR/CR»…
  type,
  category,
  currency,
  notes,

  /// SmartBudget's own export: the transaction's id (re-importing the same
  /// file adds nothing twice).
  id,

  /// The running balance: never an amount.
  balance,
}

/// Which column holds each field (absent: not in the file).
class ImportColumns {
  const ImportColumns(this.at);

  final Map<ImportField, int> at;

  int? operator [](ImportField f) => at[f];

  /// [field] read from [column] (null: from none). A column holds one field.
  ImportColumns set(ImportField field, int? column) {
    final Map<ImportField, int> m = Map<ImportField, int>.of(at)
      ..removeWhere((ImportField f, int c) => f == field || c == column);
    if (column != null) m[field] = column;
    // One amount column, or a debit/credit pair: not both.
    if (column != null && field == ImportField.amount) {
      m
        ..remove(ImportField.debit)
        ..remove(ImportField.credit);
    } else if (column != null &&
        (field == ImportField.debit || field == ImportField.credit)) {
      m.remove(ImportField.amount);
    }
    return ImportColumns(m);
  }

  /// A date and an amount (or money in/out) to read rows with.
  bool get usable =>
      at.containsKey(ImportField.date) &&
      (at.containsKey(ImportField.amount) ||
          at.containsKey(ImportField.debit) ||
          at.containsKey(ImportField.credit));
}

/// One statement line, ready to become a transaction.
class StatementRow {
  const StatementRow({
    required this.line,
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.recognized,
    this.currency,
    this.notes,
  });

  /// Its row in the file (0-based).
  final int line;
  final String id;
  final DateTime date;
  final TransactionType type;
  final double amount;
  final String description;
  final String category;

  /// False when the category fell back to «Other».
  final bool recognized;
  final String? currency;
  final String? notes;
}

class StatementRead {
  const StatementRead({
    required this.rows,
    required this.unreadable,
    required this.signed,
  });

  final List<StatementRow> rows;

  /// Lines with a date or an amount that could not be read whole.
  final int unreadable;

  /// The amount column carries signs (money out is negative): unsigned
  /// amounts are then money in. Otherwise the user says what they are.
  final bool signed;
}

/// Reads a bank statement or a transactions list exported from another app
/// (or from SmartBudget): finds the header row, guesses what each column
/// holds, and turns rows into transactions to check before adding.
abstract final class StatementParser {
  /// The header row (-1 when the file has none) and the columns it names,
  /// completed from what the cells hold.
  static ({int header, ImportColumns columns}) guess(SheetTable t) {
    int header = -1;
    Map<ImportField, int> m = <ImportField, int>{};
    for (int r = 0; r < math.min(30, t.rows.length); r++) {
      final Map<ImportField, int> h = _fromHeader(t.rows[r]);
      if (h.containsKey(ImportField.date) &&
          (h.containsKey(ImportField.amount) ||
              h.containsKey(ImportField.debit) ||
              h.containsKey(ImportField.credit))) {
        header = r;
        m = h;
        break;
      }
    }
    m = _fromContent(t, header, m);
    return (header: header, columns: ImportColumns(m));
  }

  /// The rows below [header] read with [columns]. Amounts without a sign
  /// (and no type column) are money in when [unsignedIncome].
  static StatementRead read(
    SheetTable t,
    int header,
    ImportColumns columns, {
    required DateTime today,
    bool unsignedIncome = false,
    List<String> customIncome = const <String>[],
    List<String> customExpense = const <String>[],
  }) {
    final int? cDate = columns[ImportField.date];
    final int? cAmount = columns[ImportField.amount];
    final int? cDebit = columns[ImportField.debit];
    final int? cCredit = columns[ImportField.credit];
    final int? cType = columns[ImportField.type];
    final int? cDesc = columns[ImportField.description];
    final int? cCat = columns[ImportField.category];
    final int? cCur = columns[ImportField.currency];
    final int? cNotes = columns[ImportField.notes];
    final int? cId = columns[ImportField.id];
    if (!columns.usable) {
      return const StatementRead(
          rows: <StatementRow>[], unreadable: 0, signed: false);
    }

    final Iterable<int> body = <int>[
      for (int r = header + 1; r < t.rows.length; r++) r,
    ];
    final _DateOrder order = _dateOrder(body.map((int r) => t.cell(r, cDate!)));
    String? mark(int? c) =>
        c == null ? null : _decimalMark(body.map((int r) => t.cell(r, c)));
    final String? markAmount = mark(cAmount);
    final String? markDebit = mark(cDebit);
    final String? markCredit = mark(cCredit);
    final bool signed = cAmount != null &&
        body.any((int r) =>
            (_amount(t.cell(r, cAmount), markAmount,
                        number: t.isNumber(r, cAmount))
                    ?.sign ??
                0) <
            0);

    final List<StatementRow> rows = <StatementRow>[];
    final Map<String, int> seen = <String, int>{};
    int unreadable = 0;
    for (final int r in body) {
      String cell(int? c) => c == null ? '' : t.cell(r, c).trim();
      final String description = cell(cDesc);
      if (_summary.hasMatch(description.toLowerCase())) continue;

      final DateTime? date = _date(cell(cDate), order, today);
      TransactionType? type;
      double? amount;
      if (cAmount != null) {
        final _Amount? a =
            _amount(cell(cAmount), markAmount, number: t.isNumber(r, cAmount));
        if (a != null) {
          amount = a.value;
          final bool? dir = cType == null ? null : _direction(cell(cType));
          if (dir != null) {
            type = dir ? TransactionType.income : TransactionType.expense;
          } else if (a.sign < 0) {
            type = TransactionType.expense;
          } else if (a.sign > 0 || signed || unsignedIncome) {
            type = TransactionType.income;
          } else {
            type = TransactionType.expense;
          }
        }
      } else {
        final _Amount? out = cDebit == null
            ? null
            : _amount(cell(cDebit), markDebit, number: t.isNumber(r, cDebit));
        final _Amount? inn = cCredit == null
            ? null
            : _amount(cell(cCredit), markCredit,
                number: t.isNumber(r, cCredit));
        if (out != null && out.value > 0) {
          amount = out.value;
          // A negative «debit» is money back.
          type = out.sign < 0 && cCredit == null
              ? TransactionType.income
              : TransactionType.expense;
        } else if (inn != null && inn.value > 0) {
          amount = inn.value;
          type = inn.sign < 0 && cDebit == null
              ? TransactionType.expense
              : TransactionType.income;
        }
      }
      if (date == null || amount == null || amount == 0 || type == null) {
        // A line with nothing of a transaction (a title, a footer) is not
        // a line that failed.
        if (date != null || (amount != null && amount != 0)) unreadable++;
        continue;
      }

      final String catCell = cell(cCat);
      final List<String> known = type == TransactionType.income
          ? <String>[...Catalog.incomeCategories, ...customIncome]
          : <String>[...Catalog.expenseCategories, ...customExpense];
      String? category = known.contains(catCell) ? catCell : null;
      category ??= _guess(catCell, type, today, customIncome, customExpense);
      category ??=
          _guess(description, type, today, customIncome, customExpense);

      final String cur = cell(cCur).toUpperCase();
      final String? currency =
          Currencies.all.any((Currency c) => c.code == cur) ? cur : null;

      final String key = '${DateInput.format(date)}|${type.name}|'
          '${amount.toStringAsFixed(2)}|$description';
      final int n = seen[key] = (seen[key] ?? 0) + 1;
      final String ownId = cell(cId);
      rows.add(StatementRow(
        line: r,
        id: ownId.isNotEmpty
            ? ownId
            : 'imp-${sha1.convert(utf8.encode('$key|$n')).toString().substring(0, 20)}',
        date: date,
        type: type,
        amount: amount,
        description: description,
        category: category ?? QuickEntryParser.other,
        recognized: category != null,
        currency: currency,
        notes: cell(cNotes).isEmpty ? null : cell(cNotes),
      ));
    }
    return StatementRead(rows: rows, unreadable: unreadable, signed: signed);
  }

  /// The rows already recorded in [existing] (same day, kind and amount),
  /// each existing transaction matching one row at most.
  static Set<int> alreadyRecorded(
      List<StatementRow> rows, Iterable<Transaction> existing) {
    final Set<String> ids = <String>{};
    final Map<String, int> left = <String, int>{};
    for (final Transaction t in existing) {
      ids.add(t.id);
      final String k = _key(t.date, t.type, t.amount.asDouble);
      left[k] = (left[k] ?? 0) + 1;
    }
    final Set<int> known = <int>{};
    for (int i = 0; i < rows.length; i++) {
      final StatementRow row = rows[i];
      final String k = _key(row.date, row.type, row.amount);
      if (ids.contains(row.id)) {
        known.add(i);
      } else if ((left[k] ?? 0) > 0) {
        left[k] = left[k]! - 1;
        known.add(i);
      }
    }
    return known;
  }

  static String _key(DateTime d, TransactionType t, double amount) =>
      '${d.year}-${d.month}-${d.day}|${t.name}|${(amount * 100).round()}';

  static String? _guess(String text, TransactionType type, DateTime today,
      List<String> customIncome, List<String> customExpense) {
    final String words = text.replaceAll(RegExp(r'[\d.,/:#*-]+'), ' ').trim();
    if (words.isEmpty) return null;
    final QuickEntry? g = QuickEntryParser.parse('$words 1',
        today: today, customIncome: customIncome, customExpense: customExpense);
    return g != null && g.recognized && g.type == type ? g.category : null;
  }

  // ---- Header ---------------------------------------------------------------

  /// Header words per field, in every language of the app. Earlier fields
  /// win («Debit amount» is money out, «Available balance» the balance).
  static const List<(ImportField, List<String>)> _headerWords =
      <(ImportField, List<String>)>[
    (
      ImportField.balance,
      <String>[
        'balance',
        'running bal',
        'رصيد',
        'الرصيد',
        'solde',
        'saldo',
        'kontostand',
        'bakiye',
        'остаток',
        'баланс',
        'stanje',
        'gjendja',
        'salio',
        'बैलेंस',
        'शेष',
        'بیلنس',
        'مانده',
        'موجودی',
        '余额',
        '残高',
        '잔액',
        'ragowa',
      ]
    ),
    (ImportField.id, <String>['id']),
    (
      ImportField.debit,
      <String>[
        'debit',
        'withdrawal',
        'money out',
        'paid out',
        'dr',
        'مدين',
        'سحب',
        'مسحوب',
        'خصم',
        'المدين',
        'débit',
        'cargo',
        'cargos',
        'débito',
        'saídas',
        'saida',
        'addebit',
        'uscite',
        'soll',
        'belastung',
        'af',
        'afschrijving',
        'borç',
        'расход',
        'списание',
        'дебет',
        'debet',
        'keluar',
        'isplata',
        'tërheqje',
        'kutoa',
        'नामे',
        'डेबिट',
        'निकासी',
        'برداشت',
        'بدهکار',
        'ڈیبٹ',
        '支出',
        '借方',
        '出金',
        'お引出',
        '출금',
        '찾으신',
        'cire',
      ]
    ),
    (
      ImportField.credit,
      <String>[
        'credit',
        'deposit',
        'money in',
        'paid in',
        'cr',
        'دائن',
        'إيداع',
        'ايداع',
        'الدائن',
        'crédit',
        'abono',
        'abonos',
        'crédito',
        'entradas',
        'accredit',
        'entrate',
        'haben',
        'gutschrift',
        'bij',
        'bijschrijving',
        'alacak',
        'приход',
        'зачисление',
        'кредит',
        'kredit',
        'masuk',
        'uplata',
        'depozit',
        'kuweka',
        'जमा',
        'क्रेडिट',
        'واریز',
        'بستانکار',
        'کریڈٹ',
        '收入',
        '存入',
        '贷方',
        '入金',
        'お預入',
        '입금',
        '맡기신',
        'saka',
      ]
    ),
    (
      ImportField.amount,
      <String>[
        'amount',
        'amt',
        '=value',
        '=sum',
        'montant',
        'المبلغ',
        'مبلغ',
        'القيمة',
        'importe',
        'monto',
        'valor',
        'importo',
        'betrag',
        'bedrag',
        'tutar',
        'сумма',
        'jumlah',
        'nominal',
        'iznos',
        'shuma',
        'kiasi',
        'adadi',
        'राशि',
        'رقم',
        '金额',
        '金額',
        '금액',
      ]
    ),
    (
      ImportField.date,
      <String>[
        'date',
        'تاريخ',
        'التاريخ',
        'fecha',
        'data',
        'datum',
        'buchungstag',
        'valuta',
        'tarih',
        'дата',
        'tanggal',
        'tarikh',
        'tarehe',
        'तारीख',
        'दिनांक',
        'تاریخ',
        '日期',
        '日付',
        '取引日',
        '날짜',
        '거래일',
        '일자',
        'kwanan',
      ]
    ),
    (
      ImportField.type,
      <String>[
        'type',
        'transaction type',
        'dr/cr',
        'cr/dr',
        'af bij',
        'af/bij',
        'النوع',
        'نوع',
        'tipo',
        'typ',
        'tür',
        'тип',
        'jenis',
        'vrsta',
        'lloji',
        'aina',
        'प्रकार',
        '类型',
        '種類',
        '種別',
        '구분',
        'irin',
      ]
    ),
    (
      ImportField.category,
      <String>[
        'category',
        'الفئة',
        'التصنيف',
        'تصنيف',
        'catégorie',
        'categoría',
        'categoria',
        'kategorie',
        'categorie',
        'kategori',
        'категория',
        'kategorija',
        'kategoria',
        'kundi',
        'श्रेणी',
        'دسته',
        'زمرہ',
        '类别',
        '分类',
        'カテゴリ',
        '카테고리',
        'rukuni',
      ]
    ),
    (
      ImportField.currency,
      <String>[
        'currency',
        'العملة',
        'devise',
        'moneda',
        'moeda',
        'währung',
        'valuta',
        'para birimi',
        'валюта',
        'mata uang',
        'monedha',
        'sarafu',
        'मुद्रा',
        'ارز',
        'کرنسی',
        '币种',
        '通貨',
        '통화',
        'kuɗi',
      ]
    ),
    (
      ImportField.notes,
      <String>[
        'notes',
        'note',
        'ملاحظات',
        'ملاحظة',
        'remarque',
        'notas',
        'notizen',
        'notities',
        'notlar',
        'примечание',
        'catatan',
        'bilješke',
        'shënime',
        'टिप्पणी',
        'یادداشت',
        'نوٹس',
        '备注',
        'メモ',
        '메모',
        'maelezo ya ziada',
      ]
    ),
    (
      ImportField.description,
      <String>[
        'description',
        'details',
        'detail',
        'narration',
        'particulars',
        'memo',
        'payee',
        'merchant',
        'beneficiary',
        'البيان',
        'الوصف',
        'وصف',
        'التفاصيل',
        'تفاصيل',
        'البيان',
        'libellé',
        'libelle',
        'concepto',
        'descripción',
        'descrição',
        'histórico',
        'descrizione',
        'causale',
        'beschreibung',
        'verwendungszweck',
        'buchungstext',
        'omschrijving',
        'açıklama',
        'описание',
        'назначение',
        'keterangan',
        'uraian',
        'opis',
        'përshkrim',
        'maelezo',
        'bayani',
        'विवरण',
        'شرح',
        'تفصیل',
        '摘要',
        '交易摘要',
        '说明',
        '説明',
        '内容',
        '내용',
        '적요',
      ]
    ),
  ];

  static Map<ImportField, int> _fromHeader(List<String> row) {
    final Map<ImportField, int> m = <ImportField, int>{};
    for (int c = 0; c < row.length; c++) {
      final String h = row[c]
          .toLowerCase()
          .replaceAll(RegExp(r'\(.*?\)|[:*_.]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (h.isEmpty || h.length > 40) continue;
      final ImportField? f = _fieldOf(h);
      if (f != null && !m.containsKey(f)) m[f] = c;
    }
    // A paymentMethod-style column is not the type.
    return m;
  }

  static ImportField? _fieldOf(String h) {
    // A whole-header match first («Type» before «Transaction type»'s…).
    for (final (ImportField f, List<String> words) in _headerWords) {
      if (words.contains(h) || words.contains('=$h')) return f;
    }
    for (final (ImportField f, List<String> words) in _headerWords) {
      for (final String w in words) {
        if (w.startsWith('=')) continue; // whole headers only
        // Short Latin words only whole («dr», «af», «id»), as words.
        if (w.length <= 3 && RegExp(r'^[a-z/]+$').hasMatch(w)) {
          if (RegExp('(^|[^a-z])${RegExp.escape(w)}([^a-z]|\$)').hasMatch(h)) {
            return f;
          }
        } else if (h.contains(w)) {
          return f;
        }
      }
    }
    return null;
  }

  // ---- Content --------------------------------------------------------------

  /// Fills the date, amount and description from what the cells hold when
  /// the header didn't name them.
  static Map<ImportField, int> _fromContent(
      SheetTable t, int header, Map<ImportField, int> named) {
    final Map<ImportField, int> m = Map<ImportField, int>.of(named);
    final List<int> body = <int>[
      for (int r = header + 1; r < math.min(t.rows.length, header + 81); r++) r,
    ];
    if (body.isEmpty) return m;
    final int columns = t.columns;
    final Set<int> taken = m.values.toSet();
    final DateTime today = DateTime(2100);

    double ratio(int c, bool Function(String v, int r, int c) test) {
      int filled = 0, ok = 0;
      for (final int r in body) {
        final String v = t.cell(r, c).trim();
        if (v.isEmpty) continue;
        filled++;
        if (test(v, r, c)) ok++;
      }
      return filled == 0 ? 0 : ok / filled;
    }

    double fill(int c) =>
        body.where((int r) => t.cell(r, c).trim().isNotEmpty).length /
        body.length;

    bool isDate(String v, int r, int c) =>
        _date(v, _DateOrder.dmy, today) != null;
    bool isMoney(String v, int r, int c) {
      if (isDate(v, r, c)) return false;
      final String bare = v.replaceAll(RegExp(r'[\s,.]'), '');
      // Long bare digit runs are references and account numbers.
      if (RegExp(r'^\d{6,}$').hasMatch(bare) && !v.contains(RegExp(r'[.,]'))) {
        return false;
      }
      return _amount(v, null, number: t.isNumber(r, c)) != null;
    }

    if (!m.containsKey(ImportField.date)) {
      for (int c = 0; c < columns; c++) {
        if (!taken.contains(c) && fill(c) > 0.5 && ratio(c, isDate) >= 0.8) {
          m[ImportField.date] = c;
          taken.add(c);
          break;
        }
      }
    }
    if (!m.containsKey(ImportField.amount) &&
        !m.containsKey(ImportField.debit) &&
        !m.containsKey(ImportField.credit)) {
      final List<int> money = <int>[
        for (int c = 0; c < columns; c++)
          if (!taken.contains(c) && ratio(c, isMoney) >= 0.8) c,
      ];
      // Two columns that take turns (one filled per row): out and in.
      bool takeTurns(int a, int b) => body.every((int r) =>
          t.cell(r, a).trim().isEmpty || t.cell(r, b).trim().isEmpty);
      int? pair;
      for (int i = 0; i + 1 < money.length; i++) {
        if (fill(money[i]) < 0.95 &&
            fill(money[i + 1]) < 0.95 &&
            takeTurns(money[i], money[i + 1])) {
          pair = i;
          break;
        }
      }
      if (pair != null) {
        m[ImportField.debit] = money[pair];
        m[ImportField.credit] = money[pair + 1];
        taken.addAll(<int>[money[pair], money[pair + 1]]);
      } else if (money.isNotEmpty) {
        m[ImportField.amount] = money.first;
        taken.add(money.first);
      }
    }
    if (!m.containsKey(ImportField.description)) {
      int? best;
      double bestLen = 0;
      for (int c = 0; c < columns; c++) {
        if (taken.contains(c)) continue;
        double len = 0;
        int n = 0;
        for (final int r in body) {
          final String v = t.cell(r, c).trim();
          if (v.isEmpty) continue;
          // Words, not numbers.
          if (!RegExp(r'\p{L}{2,}', unicode: true).hasMatch(v)) continue;
          len += v.length;
          n++;
        }
        if (n >= body.length / 3 && len / n > bestLen) {
          bestLen = len / n;
          best = c;
        }
      }
      if (best != null) m[ImportField.description] = best;
    }
    return m;
  }

  // ---- Cells ----------------------------------------------------------------

  static final RegExp _summary = RegExp(
      r'opening balance|closing balance|balance (brought|carried) forward|'
      r'^(grand )?totals?\s*:?$|^sub-?total|رصيد افتتاحي|الرصيد الافتتاحي|'
      r'رصيد سابق|الرصيد السابق|رصيد ختامي|الرصيد الختامي|^الإجمالي\s*:?$|'
      r'^المجموع\s*:?$|solde (initial|précédent|final|au)|'
      r'saldo (inicial|anterior|final|iniziale|finale)|anfangssaldo|endsaldo|'
      r'beginsaldo|eindsaldo|devreden|начальный остаток|конечный остаток|'
      r'期初余额|期末余额|繰越|이월');

  static bool? _direction(String v) {
    final String s = v.trim().toLowerCase();
    if (s.isEmpty) return null;
    const List<String> inWords = <String>[
      'cr',
      'c',
      '+',
      'in',
      'income',
      'credit',
      'bij',
      'دخل',
      'دائن',
      'إيراد',
      'وارد',
      'crédit',
      'haben',
      'h',
      'alacak',
      'приход',
      'kredit',
    ];
    const List<String> outWords = <String>[
      'dr',
      'd',
      '-',
      'out',
      'expense',
      'debit',
      'af',
      'مصروف',
      'مدين',
      'نفقة',
      'صادر',
      'débit',
      'soll',
      's',
      'borç',
      'расход',
      'debet',
    ];
    if (inWords.contains(s)) return true;
    if (outWords.contains(s)) return false;
    return BankMessageParser.directionOf(s);
  }

  /// The decimal mark the cells of a column use, when they show one.
  static String? _decimalMark(Iterable<String> cells) {
    int dot = 0, comma = 0;
    for (final String raw in cells) {
      final String v = raw.replaceAll(RegExp(r'[^\d.,]'), '');
      final RegExpMatch? m = RegExp(r'([.,])\d{1,2}$').firstMatch(v);
      if (m != null) {
        m[1] == '.' ? dot++ : comma++;
      } else if (v.contains('.') && v.contains(',')) {
        v.lastIndexOf('.') > v.lastIndexOf(',') ? dot++ : comma++;
      }
    }
    if (dot == comma) return null;
    return dot > comma ? '.' : ',';
  }

  static _Amount? _amount(String raw, String? mark, {bool number = false}) {
    final String v = BankMessageParser.digits(raw).trim();
    if (v.isEmpty) return null;
    if (number) {
      final double? d = double.tryParse(v);
      return d == null ? null : _Amount(d.abs(), d < 0 ? -1 : 0);
    }
    if (!RegExp(r'\d').hasMatch(v)) return null;
    final String lower = v.toLowerCase();
    int sign = 0;
    if (RegExp(r'^\(.*\)$').hasMatch(v) ||
        RegExp(r'^[^\d]*[-−–]|[-−–]\s*$').hasMatch(v) ||
        RegExp(r'\b(dr|debit)\.?$').hasMatch(lower)) {
      sign = -1;
    } else if (v.startsWith('+') ||
        RegExp(r'\b(cr|credit)\.?$').hasMatch(lower)) {
      sign = 1;
    }
    // Digits and separators only; a letter in the middle is not an amount.
    final String core = v
        .replaceAll(RegExp(r'^[^\d]+|[^\d]+$'), '')
        .replaceAll(RegExp(r'[\s  ’\x27]'), '');
    if (!RegExp(r'^\d[\d.,]*$').hasMatch(core)) return null;
    final double? d;
    if (mark == '.') {
      d = double.tryParse(core.replaceAll(',', ''));
    } else if (mark == ',') {
      d = double.tryParse(core.replaceAll('.', '').replaceAll(',', '.'));
    } else {
      d = AmountInput.parse(core);
    }
    return d == null ? null : _Amount(d, sign);
  }

  static _DateOrder _dateOrder(Iterable<String> cells) {
    for (final String c in cells) {
      final RegExpMatch? m =
          RegExp(r'^\s*(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})').firstMatch(c);
      if (m == null) continue;
      if (int.parse(m[1]!) > 12) return _DateOrder.dmy;
      if (int.parse(m[2]!) > 12) return _DateOrder.mdy;
    }
    return _DateOrder.dmy;
  }

  static DateTime? _date(String raw, _DateOrder order, DateTime today) {
    final String v = BankMessageParser.digits(raw).trim();
    if (v.isEmpty) return null;
    RegExpMatch? m;
    if ((m = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:$|[T\s])')
            .firstMatch(v)) !=
        null) {
      return DateInput.dateOf(
          int.parse(m![1]!), int.parse(m[2]!), int.parse(m[3]!));
    }
    if ((m = RegExp(r'^(\d{4})\s*[年년]\s*(\d{1,2})\s*[月월]\s*(\d{1,2})')
            .firstMatch(v)) !=
        null) {
      return DateInput.dateOf(
          int.parse(m![1]!), int.parse(m[2]!), int.parse(m[3]!));
    }
    if ((m = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})(?:$|[T\s])')
            .firstMatch(v)) !=
        null) {
      final int a = int.parse(m![1]!), b = int.parse(m[2]!);
      final int y = _year(m[3]!);
      return order == _DateOrder.dmy
          ? DateInput.dateOf(y, b, a)
          : DateInput.dateOf(y, a, b);
    }
    final String lower = v.toLowerCase();
    // «24 Oct 2026», «24-Oct-26», «24 أكتوبر 2026».
    if ((m = RegExp(
                r'^(\d{1,2})[\s\-./]*([^\d\s\-./,]+)\.?[\s\-./,]*(\d{4}|\d{2})\b',
                unicode: true)
            .firstMatch(lower)) !=
        null) {
      final int? month = _month(m![2]!);
      if (month != null) {
        return DateInput.dateOf(_year(m[3]!), month, int.parse(m[1]!));
      }
    }
    // «Oct 24, 2026».
    if ((m =
            RegExp(r'^([^\d\s,.]+)\.?\s+(\d{1,2}),?\s+(\d{4})\b', unicode: true)
                .firstMatch(lower)) !=
        null) {
      final int? month = _month(m![1]!);
      if (month != null) {
        return DateInput.dateOf(int.parse(m[3]!), month, int.parse(m[2]!));
      }
    }
    return null;
  }

  static int _year(String y) =>
      y.length == 2 ? 2000 + int.parse(y) : int.parse(y);

  /// Month names and their short forms in the languages statements come in.
  static int? _month(String word) {
    final String w = word.replaceAll('.', '');
    for (int i = 0; i < _monthNames.length; i++) {
      for (final String n in _monthNames[i]) {
        if (w == n ||
            (n.length >= 3 && w.length >= 3 && n.startsWith(w)) ||
            (w.length > 3 && w.startsWith(n) && n.length >= 3)) {
          return i + 1;
        }
      }
    }
    return null;
  }

  static const List<List<String>> _monthNames = <List<String>>[
    <String>[
      'january',
      'janvier',
      'enero',
      'januar',
      'janeiro',
      'gennaio',
      'januari',
      'ocak',
      'janar',
      'januari',
      'يناير',
      'جانفي',
      'كانون الثاني',
      'января',
      'январь',
      'janv'
    ],
    <String>[
      'february',
      'février',
      'fevrier',
      'febrero',
      'februar',
      'fevereiro',
      'febbraio',
      'februari',
      'şubat',
      'shkurt',
      'فبراير',
      'فيفري',
      'شباط',
      'февраля',
      'февраль',
      'févr'
    ],
    <String>[
      'march',
      'mars',
      'marzo',
      'märz',
      'março',
      'maart',
      'mrt',
      'mart',
      'mars',
      'مارس',
      'آذار',
      'марта',
      'март'
    ],
    <String>[
      'april',
      'avril',
      'abril',
      'aprile',
      'nisan',
      'prill',
      'أبريل',
      'ابريل',
      'أفريل',
      'نيسان',
      'апреля',
      'апрель',
      'avr'
    ],
    <String>[
      'may',
      'mai',
      'mayo',
      'maio',
      'maggio',
      'mei',
      'mayıs',
      'maj',
      'مايو',
      'ماي',
      'أيار',
      'мая',
      'май'
    ],
    <String>[
      'june',
      'juin',
      'junio',
      'juni',
      'junho',
      'giugno',
      'haziran',
      'qershor',
      'يونيو',
      'جوان',
      'حزيران',
      'июня',
      'июнь'
    ],
    <String>[
      'july',
      'juillet',
      'julio',
      'juli',
      'julho',
      'luglio',
      'temmuz',
      'korrik',
      'يوليو',
      'جويلية',
      'تموز',
      'июля',
      'июль',
      'juil'
    ],
    <String>[
      'august',
      'août',
      'aout',
      'agosto',
      'augustus',
      'ağustos',
      'agustus',
      'gusht',
      'أغسطس',
      'اغسطس',
      'أوت',
      'آب',
      'августа',
      'август'
    ],
    <String>[
      'september',
      'septembre',
      'septiembre',
      'setembro',
      'settembre',
      'eylül',
      'shtator',
      'سبتمبر',
      'أيلول',
      'сентября',
      'сентябрь',
      'sept'
    ],
    <String>[
      'october',
      'octobre',
      'octubre',
      'oktober',
      'outubro',
      'ottobre',
      'ekim',
      'tetor',
      'أكتوبر',
      'اكتوبر',
      'تشرين الأول',
      'октября',
      'октябрь'
    ],
    <String>[
      'november',
      'novembre',
      'noviembre',
      'novembro',
      'kasım',
      'nëntor',
      'نوفمبر',
      'تشرين الثاني',
      'ноября',
      'ноябрь'
    ],
    <String>[
      'december',
      'décembre',
      'decembre',
      'diciembre',
      'dezember',
      'dezembro',
      'dicembre',
      'aralık',
      'desember',
      'dhjetor',
      'ديسمبر',
      'كانون الأول',
      'декабря',
      'декабрь',
      'déc'
    ],
  ];
}

enum _DateOrder { dmy, mdy }

class _Amount {
  const _Amount(this.value, this.sign);
  final double value;

  /// -1 money out (a minus, brackets, «DR»), 1 marked in («+», «CR»), 0 none.
  final int sign;
}
