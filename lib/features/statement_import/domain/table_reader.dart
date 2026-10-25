import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// A spreadsheet read as rows of cell text.
class SheetTable {
  const SheetTable(this.rows, {this.numbers = const <int>{}});

  final List<List<String>> rows;

  /// Cells Excel stored as numbers (row * [_width] + column): their text is
  /// plain («1234.5», a dot before the decimals, no grouping).
  final Set<int> numbers;

  static const int _width = 1 << 12;
  static int key(int row, int column) => row * _width + column;

  bool isNumber(int row, int column) => numbers.contains(key(row, column));

  String cell(int row, int column) {
    final List<String> r = rows[row];
    return column < r.length ? r[column] : '';
  }

  int get columns =>
      rows.fold<int>(0, (int m, List<String> r) => r.length > m ? r.length : m);
}

/// Why a file could not be read.
enum TableError {
  /// An Excel 97–2003 workbook (.xls): to be saved again as .xlsx or .csv.
  oldExcel,

  /// Not a table: no rows, or not CSV/Excel at all.
  unreadable,
}

class TableReadException implements Exception {
  const TableReadException(this.error);
  final TableError error;

  @override
  String toString() => 'TableReadException($error)';
}

/// Reads an Excel workbook (.xlsx, the first sheet) or a CSV/TSV text file.
abstract final class TableReader {
  /// [lang] picks the old Windows code page a CSV without UTF-8 is most
  /// likely in («ar» → Arabic, «ru» → Cyrillic, else Western).
  static SheetTable read(Uint8List bytes, {String lang = 'en'}) {
    if (bytes.length >= 4 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      throw const TableReadException(TableError.oldExcel);
    }
    final SheetTable t;
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      try {
        t = xlsx(bytes);
      } on TableReadException {
        rethrow;
      } catch (_) {
        throw const TableReadException(TableError.unreadable);
      }
    } else {
      t = SheetTable(csv(decode(bytes, lang: lang)));
    }
    if (t.rows
            .where((List<String> r) => r.any((String c) => c.isNotEmpty))
            .length <
        2) {
      throw const TableReadException(TableError.unreadable);
    }
    return t;
  }

  // ---- Text ----------------------------------------------------------------

  /// UTF-8 (with or without BOM), UTF-16 with a BOM (Excel's "Unicode
  /// text"), or else the Windows code page Excel saves a CSV in.
  static String decode(Uint8List b, {String lang = 'en'}) {
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) {
      return _utf16(b.sublist(2), little: true);
    }
    if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) {
      return _utf16(b.sublist(2), little: false);
    }
    final Uint8List body =
        b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF
            ? b.sublist(3)
            : b;
    try {
      return utf8.decode(body);
    } on FormatException {
      final String table = switch (lang) {
        'ar' || 'fa' || 'ur' => _cp1256,
        'ru' => _cp1251,
        _ => _cp1252,
      };
      final StringBuffer s = StringBuffer();
      for (final int c in body) {
        s.write(c < 0x80 ? String.fromCharCode(c) : table[c - 0x80]);
      }
      return s.toString();
    }
  }

  static String _utf16(Uint8List b, {required bool little}) {
    final List<int> units = <int>[
      for (int i = 0; i + 1 < b.length; i += 2)
        little ? b[i] | (b[i + 1] << 8) : (b[i] << 8) | b[i + 1],
    ];
    return String.fromCharCodes(units);
  }

  /// CSV as Excel and banks write it: the separator is whichever of «,»
  /// «;» tab «|» splits the first lines most evenly; quoted cells may hold
  /// separators, quotes («""») and line breaks.
  static List<List<String>> csv(String text) {
    final String sep = _separator(text);
    final List<List<String>> rows = <List<String>>[];
    List<String> row = <String>[];
    final StringBuffer cell = StringBuffer();
    bool quoted = false;
    bool wasQuoted = false;
    void endCell() {
      final String v = cell.toString();
      row.add(wasQuoted ? v : v.trim());
      cell.clear();
      wasQuoted = false;
    }

    void endRow() {
      endCell();
      if (row.any((String c) => c.isNotEmpty)) rows.add(row);
      row = <String>[];
    }

    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"' && cell.toString().trim().isEmpty) {
        cell.clear();
        quoted = true;
        wasQuoted = true;
      } else if (ch == sep) {
        endCell();
      } else if (ch == '\n') {
        endRow();
      } else if (ch != '\r' && ch != '﻿') {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }

  static String _separator(String text) {
    final List<String> lines = text
        .split('\n')
        .where((String l) => l.trim().isNotEmpty)
        .take(20)
        .toList();
    String best = ',';
    double bestScore = -1;
    for (final String sep in const <String>[',', ';', '\t', '|']) {
      final List<int> counts = <int>[
        for (final String l in lines) _countOutsideQuotes(l, sep),
      ];
      if (counts.every((int c) => c == 0)) continue;
      // Most lines split the same way, into the most cells.
      final Map<int, int> freq = <int, int>{};
      for (final int c in counts) {
        freq[c] = (freq[c] ?? 0) + 1;
      }
      final MapEntry<int, int> mode = freq.entries
          .where((MapEntry<int, int> e) => e.key > 0)
          .fold<MapEntry<int, int>>(
              const MapEntry<int, int>(0, 0),
              (MapEntry<int, int> a, MapEntry<int, int> e) =>
                  e.value > a.value ? e : a);
      final double score = mode.value * 100.0 + mode.key;
      if (score > bestScore) {
        bestScore = score;
        best = sep;
      }
    }
    return best;
  }

  static int _countOutsideQuotes(String line, String sep) {
    int n = 0;
    bool q = false;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == '"') q = !q;
      if (!q && line[i] == sep) n++;
    }
    return n;
  }

  // ---- Excel ---------------------------------------------------------------

  /// The first sheet of an .xlsx workbook. Dates (numbers in a date format)
  /// come out as «yyyy-mm-dd».
  static SheetTable xlsx(Uint8List bytes) {
    final Archive zip = ZipDecoder().decodeBytes(bytes);
    XmlDocument? doc(String name) {
      final ArchiveFile? f = zip.findFile(name);
      return f == null
          ? null
          : XmlDocument.parse(utf8.decode(f.content, allowMalformed: true));
    }

    final XmlDocument? workbook = doc('xl/workbook.xml');
    if (workbook == null) throw const TableReadException(TableError.unreadable);
    final bool date1904 = workbook
        .findAllElements('workbookPr', namespaceUri: '*')
        .any((XmlElement e) {
      final String? v = e.getAttribute('date1904');
      return v == '1' || v == 'true';
    });

    // The first sheet, through the workbook's relationships.
    String sheetPath = 'xl/worksheets/sheet1.xml';
    final XmlElement? first =
        workbook.findAllElements('sheet', namespaceUri: '*').firstOrNull;
    final String? rid = first?.attributes
        .where((XmlAttribute a) => a.name.local == 'id')
        .firstOrNull
        ?.value;
    final XmlDocument? rels = doc('xl/_rels/workbook.xml.rels');
    if (rid != null && rels != null) {
      for (final XmlElement r
          in rels.findAllElements('Relationship', namespaceUri: '*')) {
        if (r.getAttribute('Id') == rid) {
          final String target = r.getAttribute('Target') ?? '';
          sheetPath = target.startsWith('/')
              ? target.substring(1)
              : 'xl/${target.replaceFirst(RegExp(r'^\./'), '')}';
        }
      }
    }
    final XmlDocument? sheet = doc(sheetPath);
    if (sheet == null) throw const TableReadException(TableError.unreadable);

    final List<String> shared = <String>[
      for (final XmlElement si in doc('xl/sharedStrings.xml')
              ?.findAllElements('si', namespaceUri: '*') ??
          const <XmlElement>[])
        si
            .findAllElements('t', namespaceUri: '*')
            .map((XmlElement t) => t.innerText)
            .join(),
    ];
    final List<bool> dateStyles = _dateStyles(doc('xl/styles.xml'));

    final List<List<String>> rows = <List<String>>[];
    final Set<int> numbers = <int>{};
    for (final XmlElement r
        in sheet.findAllElements('row', namespaceUri: '*')) {
      final List<String> row = <String>[];
      int next = 0;
      for (final XmlElement c in r.findElements('c', namespaceUri: '*')) {
        final String? ref = c.getAttribute('r');
        final int col = ref == null ? next : _column(ref);
        next = col + 1;
        final String type = c.getAttribute('t') ?? 'n';
        final String raw =
            c.findElements('v', namespaceUri: '*').firstOrNull?.innerText ?? '';
        String text;
        bool number = false;
        switch (type) {
          case 's':
            final int? i = int.tryParse(raw);
            text = i != null && i < shared.length ? shared[i] : '';
          case 'inlineStr':
            text = c
                .findAllElements('t', namespaceUri: '*')
                .map((XmlElement t) => t.innerText)
                .join();
          case 'b':
          case 'e':
            text = '';
          case 'str':
            text = raw;
          default:
            final double? v = double.tryParse(raw);
            final int style = int.tryParse(c.getAttribute('s') ?? '') ?? 0;
            if (v != null && style < dateStyles.length && dateStyles[style]) {
              text = _excelDate(v, date1904);
            } else {
              text = raw;
              number = v != null;
            }
        }
        while (row.length < col) {
          row.add('');
        }
        if (row.length == col) {
          row.add(text.trim());
        } else {
          row[col] = text.trim();
        }
        if (number) numbers.add(SheetTable.key(rows.length, col));
      }
      if (row.any((String c) => c.isNotEmpty)) {
        rows.add(row);
      } else {
        // Keep numbers' keys in step with the rows kept.
        numbers.removeWhere((int k) => k ~/ (1 << 12) == rows.length);
      }
    }
    return SheetTable(rows, numbers: numbers);
  }

  /// «B12» → 1.
  static int _column(String ref) {
    int n = 0;
    for (final int u in ref.codeUnits) {
      if (u < 0x41 || u > 0x5A) break;
      n = n * 26 + (u - 0x40);
    }
    return n - 1;
  }

  /// For each cell style: whether it shows a number as a date.
  static List<bool> _dateStyles(XmlDocument? styles) {
    if (styles == null) return const <bool>[];
    final Map<int, String> custom = <int, String>{
      for (final XmlElement f
          in styles.findAllElements('numFmt', namespaceUri: '*'))
        int.tryParse(f.getAttribute('numFmtId') ?? '') ?? -1:
            f.getAttribute('formatCode') ?? '',
    };
    final XmlElement? xfs =
        styles.findAllElements('cellXfs', namespaceUri: '*').firstOrNull;
    if (xfs == null) return const <bool>[];
    return <bool>[
      for (final XmlElement xf in xfs.findElements('xf', namespaceUri: '*'))
        _isDateFormat(
            int.tryParse(xf.getAttribute('numFmtId') ?? '') ?? 0, custom),
    ];
  }

  static bool _isDateFormat(int id, Map<int, String> custom) {
    // Built-in date formats, including the Chinese/Japanese/Korean ones.
    if ((id >= 14 && id <= 22) ||
        (id >= 27 && id <= 36) ||
        (id >= 45 && id <= 47) ||
        (id >= 50 && id <= 58)) {
      return true;
    }
    final String? code = custom[id];
    if (code == null) return false;
    // Quoted text, [colours] and escaped letters aside, a day or a year.
    final String bare = code
        .replaceAll(RegExp(r'"[^"]*"'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\\.'), '')
        .toLowerCase();
    return RegExp(r'[dy]').hasMatch(bare);
  }

  static String _excelDate(double serial, bool date1904) {
    final DateTime epoch =
        date1904 ? DateTime.utc(1904) : DateTime.utc(1899, 12, 30);
    final DateTime d = epoch.add(Duration(days: serial.floor()));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  // Bytes 0x80–0xFF of the Windows code pages Excel saves CSV files in.
  static const String _cp1252 =
      '\u20AC\uFFFD\u201A\u0192\u201E\u2026\u2020\u2021\u02C6\u2030'
      '\u0160\u2039\u0152\uFFFD\u017D\uFFFD\uFFFD\u2018\u2019\u201C'
      '\u201D\u2022\u2013\u2014\u02DC\u2122\u0161\u203A\u0153\uFFFD'
      '\u017E\u0178\u00A0\u00A1\u00A2\u00A3\u00A4\u00A5\u00A6\u00A7'
      '\u00A8\u00A9\u00AA\u00AB\u00AC\u00AD\u00AE\u00AF\u00B0\u00B1'
      '\u00B2\u00B3\u00B4\u00B5\u00B6\u00B7\u00B8\u00B9\u00BA\u00BB'
      '\u00BC\u00BD\u00BE\u00BF\u00C0\u00C1\u00C2\u00C3\u00C4\u00C5'
      '\u00C6\u00C7\u00C8\u00C9\u00CA\u00CB\u00CC\u00CD\u00CE\u00CF'
      '\u00D0\u00D1\u00D2\u00D3\u00D4\u00D5\u00D6\u00D7\u00D8\u00D9'
      '\u00DA\u00DB\u00DC\u00DD\u00DE\u00DF\u00E0\u00E1\u00E2\u00E3'
      '\u00E4\u00E5\u00E6\u00E7\u00E8\u00E9\u00EA\u00EB\u00EC\u00ED'
      '\u00EE\u00EF\u00F0\u00F1\u00F2\u00F3\u00F4\u00F5\u00F6\u00F7'
      '\u00F8\u00F9\u00FA\u00FB\u00FC\u00FD\u00FE\u00FF';
  static const String _cp1256 =
      '\u20AC\u067E\u201A\u0192\u201E\u2026\u2020\u2021\u02C6\u2030'
      '\u0679\u2039\u0152\u0686\u0698\u0688\u06AF\u2018\u2019\u201C'
      '\u201D\u2022\u2013\u2014\u06A9\u2122\u0691\u203A\u0153\u200C'
      '\u200D\u06BA\u00A0\u060C\u00A2\u00A3\u00A4\u00A5\u00A6\u00A7'
      '\u00A8\u00A9\u06BE\u00AB\u00AC\u00AD\u00AE\u00AF\u00B0\u00B1'
      '\u00B2\u00B3\u00B4\u00B5\u00B6\u00B7\u00B8\u00B9\u061B\u00BB'
      '\u00BC\u00BD\u00BE\u061F\u06C1\u0621\u0622\u0623\u0624\u0625'
      '\u0626\u0627\u0628\u0629\u062A\u062B\u062C\u062D\u062E\u062F'
      '\u0630\u0631\u0632\u0633\u0634\u0635\u0636\u00D7\u0637\u0638'
      '\u0639\u063A\u0640\u0641\u0642\u0643\u00E0\u0644\u00E2\u0645'
      '\u0646\u0647\u0648\u00E7\u00E8\u00E9\u00EA\u00EB\u0649\u064A'
      '\u00EE\u00EF\u064B\u064C\u064D\u064E\u00F4\u064F\u0650\u00F7'
      '\u0651\u00F9\u0652\u00FB\u00FC\u200E\u200F\u06D2';
  static const String _cp1251 =
      '\u0402\u0403\u201A\u0453\u201E\u2026\u2020\u2021\u20AC\u2030'
      '\u0409\u2039\u040A\u040C\u040B\u040F\u0452\u2018\u2019\u201C'
      '\u201D\u2022\u2013\u2014\uFFFD\u2122\u0459\u203A\u045A\u045C'
      '\u045B\u045F\u00A0\u040E\u045E\u0408\u00A4\u0490\u00A6\u00A7'
      '\u0401\u00A9\u0404\u00AB\u00AC\u00AD\u00AE\u0407\u00B0\u00B1'
      '\u0406\u0456\u0491\u00B5\u00B6\u00B7\u0451\u2116\u0454\u00BB'
      '\u0458\u0405\u0455\u0457\u0410\u0411\u0412\u0413\u0414\u0415'
      '\u0416\u0417\u0418\u0419\u041A\u041B\u041C\u041D\u041E\u041F'
      '\u0420\u0421\u0422\u0423\u0424\u0425\u0426\u0427\u0428\u0429'
      '\u042A\u042B\u042C\u042D\u042E\u042F\u0430\u0431\u0432\u0433'
      '\u0434\u0435\u0436\u0437\u0438\u0439\u043A\u043B\u043C\u043D'
      '\u043E\u043F\u0440\u0441\u0442\u0443\u0444\u0445\u0446\u0447'
      '\u0448\u0449\u044A\u044B\u044C\u044D\u044E\u044F';
}
