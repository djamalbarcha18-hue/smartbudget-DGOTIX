import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';

/// One parsed line of quick entry ("قهوة 200", "salaire 85000", …).
class QuickEntry {
  const QuickEntry({
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.recognized = true,
    this.walletId,
    this.currency,
  });

  final TransactionType type;
  final double amount;

  /// A catalog (or custom) category; 'أخرى' when nothing matched.
  final String category;
  final String description;
  final DateTime date;

  /// False when no keyword matched and the category fell back to "Other".
  final bool recognized;

  /// A wallet named in the text ("… CCP", "… نقد"), or the one holding the
  /// [currency] named; null = use the default.
  final String? walletId;

  /// The currency named in the text ("12 دولار", "$12", "50 ر.س") as an ISO
  /// code; null when none was named and the wallet's currency applies.
  final String? currency;
}

/// Turns short free text into transactions, entirely on the device: Arabic,
/// English, French, Indonesian, Spanish, Turkish, Malay, Urdu, German,
/// Portuguese, Italian, Dutch and Bosnian keywords map
/// to the catalog categories; income is detected from income words or a leading "+";
/// a named currency ("12 دولار") picks the wallet that holds it.
abstract final class QuickEntryParser {
  static const String other = 'أخرى';

  /// Separators between several entries typed at once. Plain commas are
  /// left alone because they can be thousands separators.
  static final RegExp _split = RegExp(r'[\n;؛،]');

  static List<QuickEntry> parseAll(
    String input, {
    required DateTime today,
    List<String> customIncome = const <String>[],
    List<String> customExpense = const <String>[],
    List<Wallet> wallets = const <Wallet>[],
    String? defaultWalletId,
  }) =>
      input
          .split(_split)
          .map((String s) => parse(s,
              today: today,
              customIncome: customIncome,
              customExpense: customExpense,
              wallets: wallets,
              defaultWalletId: defaultWalletId))
          .whereType<QuickEntry>()
          .toList();

  static QuickEntry? parse(
    String input, {
    required DateTime today,
    List<String> customIncome = const <String>[],
    List<String> customExpense = const <String>[],
    List<Wallet> wallets = const <Wallet>[],
    String? defaultWalletId,
  }) {
    String text = _latinDigits(input).trim();
    if (text.isEmpty) return null;

    // Explicit sign.
    bool? income;
    if (text.startsWith('+')) {
      income = true;
      text = text.substring(1).trim();
    } else if (text.startsWith('-') && !RegExp(r'^-\s*\d').hasMatch(text)) {
      income = false;
      text = text.substring(1).trim();
    }

    // Amount: the first number, with an optional multiplier (k, ألف, rb, mil,
    // bin, ہزار, tsd, hilj = thousand; jt, juta, milyon, mio = million;
    // لاکھ = 100 000;
    // کروڑ = 10 000 000).
    final RegExpMatch? m = RegExp(
      r'(\d[\d\s.,]*\d|\d)\s*(k|K|ك|الف|ألف|آلاف|الاف|الآف|alf|rb|ribu|jt|juta|mil|bin|milyon|mio|tsd|tausend|hiljade|hiljada|hilj|ہزار|hazar|hazaar|لاکھ|lakh|lac|کروڑ|crore|karor)?(?![\p{L}\d])',
      unicode: true,
    ).firstMatch(text);
    if (m == null) return null;
    final double? base = _number(m[1]!);
    if (base == null || base <= 0) return null;
    final double amount = base * (_multipliers[m[2]] ?? (m[2] == null ? 1 : 1000));
    String rest = '${text.substring(0, m.start)} ${text.substring(m.end)}';
    // A currency named in the text: a symbol or abbreviation first, then
    // words (the longest wins, so «ريال قطري» beats «ريال»). A word shared by
    // several currencies («ريال», «دينار») is settled against the wallets.
    List<String> named = const <String>[];
    for (final (RegExp re, List<String> codes) in _currencySymbols) {
      if (re.hasMatch(rest)) {
        named = codes;
        rest = rest.replaceFirst(re, ' ');
        break;
      }
    }
    if (named.isEmpty) {
      final String n = _withoutArticles(_normalize(rest));
      String? word;
      for (final (String w, List<String> codes) in _currencyWords) {
        if ((word == null || w.length > word.length) && _containsWord(n, w)) {
          word = w;
          named = codes;
        }
      }
      if (word != null) rest = _removeWord(rest, word);
    }

    // Date words.
    DateTime date = DateTime(today.year, today.month, today.day);
    final String norm0 = _normalize(rest);
    for (final (String word, int days) in _dateWords) {
      if (_containsWord(norm0, word)) {
        date = date.subtract(Duration(days: days));
        rest = _removeWord(rest, word);
        break;
      }
    }

    // A wallet named in the text: the user's own names first (longest wins),
    // then generic cash words for their cash wallet.
    String? walletId;
    {
      final String n = _normalize(rest);
      String? matched;
      for (final Wallet w in wallets) {
        if (w.isGeneral || w.name.trim().isEmpty) continue;
        if (_containsWord(n, w.name) &&
            (matched == null || w.name.length > matched.length)) {
          matched = w.name;
          walletId = w.id;
        }
      }
      if (matched != null) {
        rest = _removeWord(rest, matched);
      } else {
        final Wallet? cash = wallets
            .where((Wallet w) => w.type == WalletType.cash && !w.isGeneral)
            .firstOrNull;
        if (cash != null) {
          for (final String word in _cashWords) {
            if (_containsWord(n, word)) {
              walletId = cash.id;
              rest = _removeWord(rest, word);
              break;
            }
          }
        }
      }
    }

    // The named currency decides the wallet unless one was named: the default
    // wallet when it holds that currency, else the first wallet that does.
    String? currency;
    if (named.isNotEmpty) {
      String? currencyOf(String? id) =>
          wallets.where((Wallet w) => w.id == id).firstOrNull?.currency;
      final List<String?> prefer = <String?>[
        currencyOf(walletId),
        currencyOf(defaultWalletId),
        ...wallets.map((Wallet w) => w.currency),
      ];
      currency = prefer.whereType<String>().firstWhere(named.contains,
          orElse: () => named.first);
      if (walletId == null && currencyOf(defaultWalletId) != currency) {
        final Wallet? holder = wallets
                .where((Wallet w) => !w.isGeneral && w.currency == currency)
                .firstOrNull ??
            wallets
                .where((Wallet w) => w.isGeneral && w.currency == currency)
                .firstOrNull;
        walletId = holder?.id;
      }
    }

    final String norm = _normalize(rest);
    if (income == null &&
        _incomeMarkers.any((String w) => _containsWord(norm, w))) {
      income = true;
    }

    // Custom categories first (the user's own words), then the keyword table.
    String? category;
    TransactionType? typeFromCategory;
    for (final String c in customIncome) {
      if (c.trim().isNotEmpty && _containsWord(norm, _normalize(c))) {
        category = c;
        typeFromCategory = TransactionType.income;
        break;
      }
    }
    if (category == null) {
      for (final String c in customExpense) {
        if (c.trim().isNotEmpty && _containsWord(norm, _normalize(c))) {
          category = c;
          typeFromCategory = TransactionType.expense;
          break;
        }
      }
    }
    if (category == null) {
      int best = 0;
      for (final _Rule r in _rules) {
        for (final String k in r.keywords) {
          final String nk = _normalize(k);
          if (nk.length > best && _containsWord(norm, nk)) {
            best = nk.length;
            category = r.category;
            typeFromCategory = r.type;
          }
        }
      }
    }

    final TransactionType type = income == true
        ? TransactionType.income
        : income == false
            ? TransactionType.expense
            : typeFromCategory ?? TransactionType.expense;

    // A keyword of the other type (e.g. "+ قهوة") doesn't fit: fall back.
    final bool fits = category != null && typeFromCategory == type;
    final String description =
        rest.replaceAll(RegExp(r'\s+'), ' ').trim();

    return QuickEntry(
      type: type,
      amount: amount,
      category: fits ? category : other,
      description: description,
      date: date,
      recognized: fits,
      walletId: walletId,
      currency: currency,
    );
  }

  // ---- Helpers ---------------------------------------------------------------

  static String _latinDigits(String s) {
    final StringBuffer b = StringBuffer();
    for (final int r in s.runes) {
      if (r >= 0x0660 && r <= 0x0669) {
        b.writeCharCode(0x30 + r - 0x0660);
      } else if (r >= 0x06F0 && r <= 0x06F9) {
        b.writeCharCode(0x30 + r - 0x06F0);
      } else if (r == 0x066B) {
        b.write('.');
      } else if (r == 0x066C) {
        b.write(',');
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }

  /// Multipliers other than a thousand (the default for any other word).
  static const Map<String, double> _multipliers = <String, double>{
    'jt': 1e6, 'juta': 1e6, 'milyon': 1e6, 'mio': 1e6,
    'لاکھ': 1e5, 'lakh': 1e5, 'lac': 1e5,
    'کروڑ': 1e7, 'crore': 1e7, 'karor': 1e7,
  };

  /// "12,500" / "12.500" / "12 500" / "1,50,000" (lakh grouping) → 12500…;
  /// "12,5" / "12.5" → 12.5.
  static double? _number(String raw) {
    String s = raw.replaceAll(RegExp(r'\s'), '');
    final RegExp grouped = RegExp(r'^\d{1,3}([.,]\d{3})+$');
    if (RegExp(r'^\d{1,3}(,\d{2})+,\d{3}$').hasMatch(s)) {
      s = s.replaceAll(',', '');
    } else if (grouped.hasMatch(s) && !(s.contains('.') && s.contains(','))) {
      s = s.replaceAll(RegExp(r'[.,]'), '');
    } else {
      final int lastSep = s.lastIndexOf(RegExp(r'[.,]'));
      if (lastSep != -1) {
        final String intPart =
            s.substring(0, lastSep).replaceAll(RegExp(r'[.,]'), '');
        s = '$intPart.${s.substring(lastSep + 1)}';
      }
    }
    return double.tryParse(s);
  }

  static String _normalize(String s) {
    String t = s.toLowerCase();
    t = t.replaceAll(RegExp('[ً-ْٰـ]'), '');
    const Map<String, String> map = <String, String>{
      'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و',
      'ئ': 'ي', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'à': 'a', 'â': 'a',
      'ç': 'c', 'î': 'i', 'ï': 'i', 'ô': 'o', 'û': 'u', 'ù': 'u', 'á': 'a',
      'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', 'ä': 'a', 'ß': 'ss', 'ã': 'a', 'õ': 'o', 'ì': 'i', 'ò': 'o',
      // Bosnian.
      'č': 'c', 'ć': 'c', 'đ': 'dj', 'š': 's', 'ž': 'z',
      // Turkish (and the dot İ leaves after toLowerCase).
      'ş': 's', 'ğ': 'g', 'ı': 'i', 'ö': 'o', '\u0307': '',
      // Urdu letters read as their Arabic forms, so shared words match.
      'ی': 'ي', 'ے': 'ي', 'ک': 'ك', 'ہ': 'ه', 'ۃ': 'ه', 'ھ': 'ه', 'ۂ': 'ه',
    };
    final StringBuffer b = StringBuffer();
    for (final String ch in t.split('')) {
      b.write(map[ch] ?? ch);
    }
    return ' ${b.toString().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim()} ';
  }

  /// Drops the Arabic article from every word («الريال السعودي» → «ريال
  /// سعودي») of a normalized string.
  static String _withoutArticles(String normalized) =>
      normalized.replaceAll(RegExp(r'(?<= )ال(?=\S\S)'), '');

  static const List<String> _arPrefixes = <String>[
    '', 'ال', 'وال', 'بال', 'فال', 'كال', 'لل', 'و', 'ب', 'ف', 'ل', 'ك',
  ];

  /// Whole-word match; Arabic words may carry a clitic prefix (ال، بال، و…).
  static bool _containsWord(String normalized, String word) {
    final String w = _normalize(word).trim();
    if (w.isEmpty) return false;
    final bool arabic = RegExp(r'[؀-ۿ]').hasMatch(w);
    if (!arabic) return normalized.contains(' $w ');
    for (final String p in _arPrefixes) {
      if (normalized.contains(' $p$w ')) return true;
    }
    return false;
  }

  /// Drops the raw tokens that spell [word] (compared in normalized form, so
  /// «أمس» is removed by «امس»).
  static String _removeWord(String s, String word) {
    final List<String> want = _normalize(word).trim().split(' ');
    final List<String> tokens = s.trim().split(RegExp(r'\s+'));
    final List<String> norm =
        tokens.map((String t) => _normalize(t).trim()).toList();
    for (int i = 0; i + want.length <= tokens.length; i++) {
      bool ok = true;
      for (int j = 0; j < want.length && ok; j++) {
        final String t = norm[i + j];
        ok = j == 0
            ? _arPrefixes.any((String p) => t == '$p${want[j]}')
            : t == want[j] || t == 'ال${want[j]}';
      }
      if (ok) {
        tokens.removeRange(i, i + want.length);
        return tokens.join(' ');
      }
    }
    return s;
  }

  static const List<(String, int)> _dateWords = <(String, int)>[
    ('اول امس', 2),
    ('قبل امس', 2),
    ('avant-hier', 2),
    ('امس', 1),
    ('البارح', 1),
    ('البارحه', 1),
    ('yesterday', 1),
    ('hier', 1),
    ('اليوم', 0),
    ('today', 0),
    ('aujourd hui', 0),
    ('kemarin lusa', 2),
    ('kemarin', 1),
    ('hari ini', 0),
    ('anteayer', 2),
    ('antier', 2),
    ('ayer', 1),
    ('hoy', 0),
    ('evvelsi gün', 2),
    ('önceki gün', 2),
    ('dün', 1),
    ('bugün', 0),
    ('kelmarin', 2),
    ('semalam', 1),
    ('پرسوں', 2),
    ('parson', 2),
    // Not «کل»: it reads like Arabic «كل» ("every") once normalized.
    ('kal', 1),
    ('آج', 0),
    ('aaj', 0),
    ('vorgestern', 2),
    ('gestern', 1),
    ('heute', 0),
    ('anteontem', 2),
    ('ontem', 1),
    ('hoje', 0),
    ('l altro ieri', 2),
    ('altro ieri', 2),
    ('ieri', 1),
    ('oggi', 0),
    ('eergisteren', 2),
    ('gisteren', 1),
    ('vandaag', 0),
    ('prekjuče', 2),
    ('prekjucer', 2),
    ('jučer', 1),
    ('juče', 1),
    ('danas', 0),
  ];

  /// Every currency the app supports, the US dollar first so a bare «دولار»
  /// means it unless the user's wallets say otherwise.
  static final List<Currency> _currencies = <Currency>[
    Currencies.usd,
    ...Currencies.all.where((Currency c) => c.code != Currencies.usd.code),
  ];

  /// Words that are also everyday words ("try", "won", «بين» = ب + ين): never
  /// read as a currency on their own.
  static const Set<String> _riskyWords = <String>{
    'try', 'mad', 'rub', 'won', 'real', 'ين',
  };

  /// Symbols, Arabic abbreviations and upper-case ISO codes, matched on the
  /// raw text (longest first, so "C$" is not read as "$").
  static final List<(RegExp, List<String>)> _currencySymbols = () {
    final Map<String, List<String>> bySymbol = <String, List<String>>{};
    for (final Currency c in _currencies) {
      for (final String sym in <String>[c.symbol, c.code]) {
        if (sym.length < 2 && RegExp(r'^\p{L}$', unicode: true).hasMatch(sym)) {
          continue; // a lone letter ("R") is too ambiguous
        }
        final List<String> codes = bySymbol.putIfAbsent(sym, () => <String>[]);
        if (!codes.contains(c.code)) codes.add(c.code);
      }
    }
    final List<String> symbols = bySymbol.keys.toList()
      ..sort((String x, String y) => y.length.compareTo(x.length));
    return <(RegExp, List<String>)>[
      for (final String sym in symbols)
        (
          RegExp(
              '(?<![\\p{L}])'
              '${RegExp.escape(sym).replaceAll(r'\.', r'\s*\.\s*')}'
              '(?![\\p{L}])',
              unicode: true),
          bySymbol[sym]!,
        ),
    ];
  }();

  /// Currency words (normalized, without «ال») → the currencies they can mean,
  /// most likely first: each currency's Arabic and English name, its bare
  /// noun («ريال», "dinar", "dollars") and its lower-case code, plus
  /// colloquial forms.
  static final List<(String, List<String>)> _currencyWords = () {
    final Map<String, List<String>> m = <String, List<String>>{};
    String key(String w) => _withoutArticles(_normalize(w)).trim();
    void add(String word, String code) {
      final String w = key(word);
      if (w.isEmpty || _riskyWords.contains(w)) return;
      final List<String> codes = m.putIfAbsent(w, () => <String>[]);
      if (!codes.contains(code)) codes.add(code);
    }

    for (final Currency c in _currencies) {
      add(c.nameAr, c.code); // «ريال سعودي»
      add(c.nameEn, c.code); // "saudi riyal"
      add(key(c.nameAr).split(' ').first, c.code); // «ريال»
      final String noun = c.nameEn.toLowerCase().split(' ').last;
      if (!_riskyWords.contains(noun)) {
        add(noun, c.code); // "riyal"
        add('${noun}s', c.code); // "riyals"
      }
      add(c.code.toLowerCase(), c.code); // "usd"
    }
    for (final (String alias, String word) in _currencyAliases) {
      for (final String code in m[key(word)] ?? <String>[word]) {
        add(alias, code);
      }
    }
    return <(String, List<String>)>[
      for (final MapEntry<String, List<String>> e in m.entries) (e.key, e.value),
    ];
  }();

  /// Colloquial forms → the word (or ISO code) they stand for.
  static const List<(String, String)> _currencyAliases = <(String, String)>[
    ('دولارات', 'دولار'),
    ('دولارين', 'دولار'),
    ('ريالات', 'ريال'),
    ('ريالين', 'ريال'),
    ('دنانير', 'دينار'),
    ('دينارين', 'دينار'),
    ('دراهم', 'درهم'),
    ('درهمين', 'درهم'),
    ('جنيهات', 'جنيه'),
    ('جنيهين', 'جنيه'),
    ('ليرات', 'ليره'),
    ('اورو', 'يورو'),
    ('استرليني', 'GBP'),
    ('pound', 'GBP'),
    ('pounds', 'GBP'),
    ('دج', 'DZD'),
    ('da', 'DZD'),
    ('tl', 'TRY'),
    ('rm', 'MYR'),
    ('روپے', 'PKR'),
    ('روپیہ', 'PKR'),
    ('روپیے', 'PKR'),
    ('rs', 'PKR'),
  ];

  static const List<String> _cashWords = <String>[
    'نقدا', 'نقد', 'كاش', 'cash', 'especes', 'espece', 'liquide', 'tunai', 'efectivo',
    'nakit', 'peşin', 'کیش', 'bargeld', 'dinheiro', 'contanti', 'contant', 'gotovina',
  ];

  static const List<String> _incomeMarkers = <String>[
    'دخل', 'استلمت', 'قبضت', 'وصلني', 'ربحت', 'received', 'income', 'earned',
    'recu', 'encaisse', 'terima', 'diterima', 'gajian', 'cobre', 'recibi', 'ingreso',
    'aldım', 'gelir', 'kazandım', 'tahsilat', 'dapat', 'pendapatan',
    'آمدنی', 'ملے', 'وصول', 'aamdani', 'erhalten', 'bekommen', 'einnahme',
    'recebi', 'ganhei', 'ricevuto', 'incassato', 'entrata',
    'ontvangen', 'inkomen', 'binnengekregen', 'primio', 'primila', 'prihod',
  ];

  static const List<_Rule> _rules = <_Rule>[
    // ---- Income
    _Rule.income('راتب أساسي', <String>[
      'راتب', 'الشهريه', 'شهريه', 'معاش شهري', 'salaire', 'salary', 'paie',
      'paycheck', 'payroll', 'gaji', 'gajian', 'sueldo', 'salario', 'nomina', 'quincena',
      'maaş', 'maaşım', 'tankhwah', 'تنخواہ',
      'gehalt', 'lohn',
      'salário', 'salario',
      'stipendio', 'busta paga',
      'salaris', 'loon',
      'plata', 'plaća',
    ]),
    _Rule.income('مكافآت وحوافز', <String>['مكافاه', 'حوافز', 'بريم', 'prime', 'bonus', 'thr', 'insentif', 'bono', 'aguinaldo', 'prima', 'ikramiye', 'prim', 'elaun', 'بونس', 'prämie', 'weihnachtsgeld', 'urlaubsgeld', 'bônus', 'décimo terceiro', 'plr', 'premio', 'tredicesima', 'quattordicesima', 'vakantiegeld', 'dertiende maand', 'bonus plata', 'stimulacija', 'regres']),
    _Rule.income('معاش تقاعدي', <String>['تقاعد', 'retraite', 'pension', 'jubilacion', 'emekli', 'emekli maaşı', 'pencen', 'پنشن', 'rente', 'aposentadoria', 'inss', 'pensione', 'aow', 'penzija']),
    _Rule.income('عمل حر', <String>['فريلانس', 'عمل حر', 'freelance', 'client', 'serbest', 'kerja bebas', 'فری لانس', 'freiberuflich', 'honorar', 'freela', 'autônomo', 'partita iva', 'fattura emessa', 'zzp', 'opdracht', 'honorar']),
    _Rule.income('عمولات', <String>['عموله', 'commission', 'comision', 'komisyon', 'komisen', 'کمیشن', 'provision', 'comissão', 'provvigione', 'provisie', 'provizija']),
    _Rule.income('بيع أصول أو ممتلكات', <String>['بعت', 'بيع', 'vente', 'vendu', 'sold', 'jual', 'terjual', 'venta', 'vendi', 'sattım', 'satış', 'بیچا', 'فروخت', 'becha', 'verkauft', 'verkauf', 'vendi', 'venda', 'venduto', 'vendita', 'verkocht', 'marktplaats', 'prodao', 'prodaja', 'olx']),
    _Rule.income('استرداد أو تعويض', <String>[
      'استرجاع', 'تعويض', 'استرداد', 'remboursement', 'refund', 'reembolso', 'devolucion',
      'iade', 'bayaran balik', 'واپسی', 'ریفنڈ',
      'erstattung', 'rückerstattung', 'gutschrift',
      'reembolso', 'estorno',
      'rimborso',
      'terugbetaling', 'teruggave', 'restitutie',
      'povrat novca', 'refundacija',
    ]),
    _Rule.income('منحة أو إعانة', <String>['منحه', 'اعانه', 'bourse', 'allocation', 'grant', 'burs', 'biasiswa', 'bantuan', 'وظیفہ', 'امداد', 'kindergeld', 'stipendium', 'bafög', 'zuschuss', 'auxílio', 'bolsa família', 'bolsa de estudos', 'borsa di studio', 'assegno unico', 'sussidio', 'toeslag', 'kinderbijslag', 'zorgtoeslag', 'huurtoeslag', 'studiefinanciering', 'uitkering', 'stipendija', 'dječiji dodatak', 'socijalna pomoć']),
    _Rule.income('إيجارات', <String>['مداخيل الكراء', 'rent income', 'loyer recu', 'kira geliri', 'sewa diterima', 'کرایہ ملا', 'mieteinnahme', 'mieteinnahmen', 'aluguel recebido', 'affitto incassato', 'huurinkomsten', 'kirija primljena']),
    // ---- Expenses
    _Rule.expense('الطعام', <String>[
      'خضر', 'خضره', 'خضار', 'فواكه', 'فاكهه', 'لحم', 'دجاج', 'حوت', 'سمك',
      'خبز', 'حليب', 'بيض', 'سكر', 'زيت', 'بقاله', 'سوبرماركت', 'سوق',
      'مواد غذائيه', 'قضيان', 'courses', 'marche', 'epicerie', 'pain', 'lait',
      'supermarche', 'boulangerie', 'groceries', 'sayur', 'buah', 'daging',
      'ayam', 'ikan', 'beras', 'telur', 'roti', 'susu', 'belanja dapur',
      'pasar', 'indomaret', 'alfamart', 'supermercado', 'mercado', 'pan',
      'leche', 'verduras', 'fruta', 'carne', 'pollo', 'huevos', 'grocery', 'supermarket', 'bread', 'milk',
      'bakkal', 'manav', 'ekmek', 'süt', 'tavuk', 'sebze', 'meyve', 'migros', 'a101', 'barang dapur', 'kedai runcit', 'pasar raya', 'mydin', 'راشن', 'سودا', 'سبزی', 'پھل', 'گوشت', 'مرغی', 'دودھ', 'آٹا', 'انڈے', 'ration', 'sabzi', 'doodh', 'atta', 'kiryana',
      'lebensmittel', 'supermarkt', 'brot', 'milch', 'obst', 'gemüse', 'fleisch', 'eier', 'bäcker', 'bäckerei', 'rewe', 'edeka', 'aldi', 'lidl', 'penny', 'kaufland',
      'mercado', 'feira', 'supermercado', 'padaria', 'pão', 'leite', 'açougue', 'hortifruti', 'carrefour', 'assaí', 'atacadão',
      'spesa', 'supermercato', 'pane', 'latte', 'frutta', 'verdura', 'carne', 'esselunga', 'conad', 'coop', 'lidl', 'eurospin',
      'boodschappen', 'supermarkt', 'brood', 'melk', 'groente', 'fruit', 'vlees', 'albert heijn', 'jumbo', 'aldi', 'lidl',
      'namirnice', 'market', 'pekara', 'hljeb', 'mlijeko', 'meso', 'voće', 'povrće', 'bingo', 'konzum', 'amko',
    ]),
    _Rule.expense('المطاعم', <String>[
      'مطعم', 'قهوه', 'كافيه', 'كافي', 'بيتزا', 'شاورما', 'كرانتيكا',
      'سندويش', 'سندويتش', 'غداء', 'عشاء', 'فطور', 'restaurant', 'cafe',
      'coffee', 'pizza', 'dejeuner', 'diner', 'resto', 'makan', 'kopi',
      'warung', 'bakso', 'nasi', 'jajan', 'sarapan', 'gofood', 'grabfood',
      'comida', 'almuerzo', 'cena', 'desayuno', 'restaurante', 'tacos',
      'lunch', 'dinner', 'breakfast', 'fast food', 'snack',
      'burger', 'tacos',
      'restoran', 'kahve', 'çay', 'yemek', 'döner', 'kebap', 'lahmacun', 'kahvaltı', 'öğle yemeği', 'akşam yemeği', 'simit', 'yemeksepeti', 'mamak', 'teh tarik', 'roti canai', 'foodpanda', 'ریسٹورنٹ', 'ہوٹل', 'چائے', 'کھانا', 'ناشتہ', 'بریانی', 'chai', 'khana', 'nashta', 'biryani',
      'kaffee', 'mittagessen', 'abendessen', 'frühstück', 'essen gehen', 'imbiss', 'lieferando',
      'café', 'almoço', 'jantar', 'lanche', 'restaurante', 'ifood', 'marmita', 'pastel',
      'caffè', 'bar', 'pranzo', 'cena', 'colazione', 'ristorante', 'pizzeria', 'aperitivo', 'gelato', 'deliveroo', 'glovo',
      'koffie', 'lunch', 'avondeten', 'ontbijt', 'eten bestellen', 'thuisbezorgd', 'snackbar', 'friet', 'broodje',
      'kafa', 'kahva', 'ćevapi', 'burek', 'ručak', 'večera', 'doručak', 'restoran', 'pizza',
    ]),
    _Rule.expense('النقل', <String>[
      'تاكسي', 'طاكسي', 'حافله', 'باص', 'ترامواي', 'ميترو', 'مترو', 'قطار',
      'نقل', 'كورسا', 'taxi', 'bus', 'tram', 'metro', 'train', 'uber', 'yassir',
      'heetch', 'transport', 'ojek', 'gojek', 'grab', 'angkot', 'krl',
      'kereta', 'parkir', 'tol', 'autobus', 'camion', 'colectivo', 'pasaje',
      'estacionamiento', 'peaje',
      'otobüs', 'dolmuş', 'taksi', 'marmaray', 'istanbulkart', 'otopark', 'köprü', 'otoyol', 'teksi', 'bas', 'lrt', 'mrt', 'grab car', 'رکشہ', 'رکشا', 'ٹیکسی', 'بس', 'rickshaw', 'careem', 'indrive', 'bykea',
      'bahn', 'zug', 'u bahn', 's bahn', 'fahrkarte', 'deutschlandticket', 'parken', 'maut', 'flixbus',
      'ônibus', 'metrô', 'uber', 'passagem', 'estacionamento', 'pedágio', 'bilhete único',
      'autobus', 'treno', 'metro', 'biglietto', 'trenitalia', 'italo', 'parcheggio', 'autostrada', 'pedaggio',
      'ov', 'trein', 'tram', 'metro', 'ov chipkaart', 'parkeren', 'tol',
      'autobus', 'tramvaj', 'taksi', 'gradski prevoz', 'parking', 'putarina',
    ]),
    _Rule.expense('الوقود', <String>[
      'بنزين', 'وقود', 'مازوت', 'ليصانص', 'essence', 'carburant', 'gasoil',
      'diesel', 'fuel', 'petrol', 'gasoline', 'bensin', 'pertalite',
      'pertamax', 'gasolina', 'combustible', 'nafta',
      'benzin', 'mazot', 'akaryakıt', 'motorin', 'lpg', 'minyak', 'ron95', 'پیٹرول', 'ڈیزل',
      'tanken', 'sprit',
      'gasolina', 'etanol', 'álcool', 'combustível', 'posto',
      'benzina', 'gasolio', 'rifornimento',
      'tanken', 'benzine',
      'gorivo', 'benzin', 'dizel', 'pumpa',
    ]),
    _Rule.expense('السكن', <String>['كراء', 'ايجار', 'loyer', 'rent', 'kos', 'kost', 'kontrakan', 'sewa rumah', 'alquiler', 'renta', 'arriendo', 'kira', 'aidat', 'sewa', 'sewa bilik', 'مکان کا کرایہ', 'کرایہ مکان', 'kiraya', 'miete', 'aluguel', 'condomínio', 'affitto', 'condominio', 'mutuo casa', 'huur', 'hypotheek', 'kirija', 'stanarina']),
    _Rule.expense('الفواتير', <String>[
      'فاتوره', 'كهرباء', 'ضو', 'ماء', 'غاز', 'سونلغاز', 'سيال', 'facture',
      'electricite', 'eau', 'gaz', 'listrik', 'pln', 'pdam', 'token listrik', 'luz', 'agua', 'factura',
      'sonelgaz', 'seaal', 'electricity', 'water bill', 'bill',
      'fatura', 'elektrik', 'su faturası', 'doğalgaz', 'bil', 'tnb', 'bil elektrik', 'bil air', 'بل', 'بجلی', 'گیس بل', 'پانی', 'bijli', 'wapda', 'sui gas',
      'strom', 'wasser', 'heizung', 'nebenkosten', 'rechnung', 'rundfunkbeitrag',
      'conta de luz', 'conta de água', 'energia', 'boleto', 'iptu',
      'bolletta', 'luce', 'acqua', 'gas metano', 'enel',
      'energie', 'stroom', 'water', 'gas en licht', 'rekening', 'gemeentelijke belastingen',
      'struja', 'voda', 'grijanje', 'komunalije', 'režije', 'račun za struju',
    ]),
    _Rule.expense('الاتصالات والإنترنت', <String>[
      'انترنت', 'فليكسي', 'رصيد', 'هاتف', 'موبيليس', 'جيزي', 'اوريدو',
      'اتصالات الجزائر', 'idoom', 'flexy', 'internet', 'wifi', 'phone',
      'mobile', 'telephone', 'recharge', 'pulsa', 'kuota', 'paket data',
      'indihome', 'movil', 'celular', 'telefono', 'recarga', 'saldo', 'mobilis', 'djezzy', 'ooredoo', 'forfait',
      'telefon', 'turkcell', 'vodafone', 'türk telekom', 'kontör', 'topup', 'reload', 'prepaid', 'celcom', 'maxis', 'digi', 'unifi', 'موبائل', 'لوڈ', 'بیلنس', 'انٹرنیٹ', 'jazz', 'zong', 'telenor', 'ufone', 'easyload', 'load',
      'handy', 'telekom', 'o2', 'mobilfunk', 'handyvertrag',
      'celular', 'recarga', 'internet',
      'ricarica', 'telefono', 'tim', 'wind tre', 'iliad', 'fastweb',
      'telefoon', 'beltegoed', 'mobiel', 'kpn', 'odido', 'ziggo',
      'mobitel', 'kredit za mobitel', 'bh telecom', 'm tel', 'eronet',
    ]),
    _Rule.expense('الصحة', <String>[
      'صيدليه', 'دواء', 'ادويه', 'طبيب', 'دكتور', 'مستشفى', 'عياده',
      'تحاليل', 'اشعه', 'pharmacie', 'medecin', 'docteur', 'medicament', 'medicaments',
      'clinique', 'pharmacy', 'doctor', 'medicine', 'clinic', 'dentist',
      'dentiste', 'obat', 'apotek', 'dokter', 'rumah sakit', 'bpjs', 'farmacia', 'medico', 'medicina',
      'consulta', 'dentista',
      'eczane', 'ilaç', 'hastane', 'muayene', 'diş', 'klinik', 'farmasi', 'ubat', 'hospital', 'doktor', 'دوائی', 'دوا', 'ڈاکٹر', 'ہسپتال', 'کلینک', 'میڈیکل', 'dawai',
      'apotheke', 'arzt', 'zahnarzt', 'krankenhaus', 'medikamente',
      'farmácia', 'remédio', 'médico', 'consulta', 'hospital', 'dentista', 'plano de saúde',
      'farmacia', 'medico', 'dentista', 'visita', 'ticket sanitario', 'ospedale',
      'apotheek', 'huisarts', 'tandarts', 'ziekenhuis', 'medicijnen', 'eigen risico',
      'apoteka', 'ljekar', 'doktor', 'stomatolog', 'bolnica', 'lijekovi',
    ]),
    _Rule.expense('التعليم', <String>[
      'مدرسه', 'جامعه', 'دروس', 'كتب', 'كتاب', 'كورس', 'دوره تدريبيه', 'كراريس', 'ادوات مدرسيه', 'تسجيل',
      'ecole', 'cours', 'livres', 'fournitures', 'school', 'tuition', 'books',
      'course', 'sekolah', 'spp', 'kuliah', 'buku', 'les', 'escuela', 'colegio', 'universidad', 'libros',
      'colegiatura',
      'okul', 'dershane', 'kurs', 'kitap', 'üniversite', 'yuran', 'tuisyen', 'اسکول', 'سکول', 'ٹیوشن', 'کتابیں', 'کالج', 'یونیورسٹی',
      'schule', 'uni', 'universität', 'bücher', 'buch', 'nachhilfe', 'studiengebühr',
      'escola', 'faculdade', 'mensalidade', 'curso', 'livros', 'material escolar',
      'scuola', 'università', 'libri', 'corso', 'retta',
      'school', 'studie', 'collegegeld', 'boeken', 'cursus',
      'škola', 'fakultet', 'knjige', 'kurs', 'školarina',
    ]),
    _Rule.expense('الأطفال والعائلة', <String>[
      'حفاظات', 'حليب اطفال', 'روضه', 'حضانه', 'creche', 'couches', 'diapers',
      'kids', 'baby', 'popok', 'panales', 'guarderia',
      'bebek bezi', 'kreş', 'lampin', 'susu bayi', 'taska', 'tadika', 'پیمپر',
      'windeln', 'kita', 'kindergarten', 'babynahrung',
      'fralda', 'creche', 'berçário',
      'pannolini', 'asilo', 'nido',
      'luiers', 'kinderopvang', 'creche',
      'pelene', 'vrtić',
    ]),
    _Rule.expense('الملابس', <String>[
      'ملابس', 'حذاء', 'صباط', 'سروال', 'قميص', 'جاكيت', 'vetements',
      'chaussures', 'clothes', 'shoes', 'jacket', 'baju', 'sepatu', 'celana', 'ropa', 'zapatos', 'zapatillas',
      'kıyafet', 'giyim', 'ayakkabı', 'pantolon', 'gömlek', 'mont', 'pakaian', 'kasut', 'کپڑے', 'جوتے', 'kapray', 'joote',
      'kleidung', 'schuhe', 'jacke', 'hose', 'zalando',
      'roupa', 'roupas', 'sapato', 'tênis', 'camisa', 'calça',
      'vestiti', 'scarpe', 'giacca', 'pantaloni', 'maglietta',
      'kleding', 'schoenen', 'jas', 'broek',
      'odjeća', 'obuća', 'cipele', 'jakna', 'patike',
    ]),
    _Rule.expense('التسوق', <String>['تسوق', 'مشتريات', 'jumia', 'amazon', 'shopping', 'aliexpress', 'shopee', 'tokopedia', 'lazada', 'belanja online', 'compras', 'mercado libre', 'trendyol', 'hepsiburada', 'alışveriş', 'beli-belah', 'شاپنگ', 'خریداری', 'daraz', 'onlineshop', 'online bestellung', 'compras', 'shopee', 'mercado livre', 'magalu', 'acquisti online', 'zalando', 'winkelen', 'bol com', 'webshop', 'kupovina', 'šoping']),
    _Rule.expense('الترفيه', <String>['سينما', 'ترفيه', 'نزهه', 'cinema', 'sortie', 'games', 'concert', 'bioskop', 'nonton', 'cine', 'salida', 'fiesta', 'sinema', 'konser', 'eğlence', 'wayang', 'سنیما', 'تفریح', 'kino', 'konzert', 'ausflug', 'freizeit', 'cinema', 'show', 'passeio', 'balada', 'cinema', 'concerto', 'uscita', 'svago', 'bioscoop', 'concert', 'uitje', 'kino', 'koncert', 'izlazak']),
    _Rule.expense('الاشتراكات', <String>[
      'اشتراك', 'netflix', 'spotify', 'youtube', 'abonnement', 'subscription',
      'shahid', 'شاهد', 'langganan', 'suscripcion',
      'abonelik', 'üyelik', 'سبسکرپشن',
      'abo', 'mitgliedschaft',
      'assinatura', 'mensalidade netflix',
      'abbonamento',
      'abonnement',
      'pretplata', 'članarina',
    ]),
    _Rule.expense('الرياضة واللياقة', <String>['جيم', 'نادي رياضي', 'رياضه', 'gym', 'salle de sport', 'fitness', 'spor salonu', 'gim', 'جم', 'fitnessstudio', 'academia', 'smart fit', 'palestra', 'sportschool', 'teretana']),
    _Rule.expense('السفر', <String>['سفر', 'فندق', 'طياره', 'طيران', 'hotel', 'flight', 'voyage', 'travel', 'billet avion', 'tiket pesawat', 'liburan', 'viaje', 'vuelo', 'vacaciones', 'otel', 'uçak', 'uçak bileti', 'tatil', 'seyahat', 'percutian', 'tiket kapal terbang', 'ٹکٹ', 'reise', 'urlaub', 'flug', 'viagem', 'hotel', 'passagem aérea', 'voo', 'férias', 'viaggio', 'vacanza', 'volo', 'albergo', 'reis', 'vakantie', 'vlucht', 'vliegticket', 'putovanje', 'avionska karta', 'odmor']),
    _Rule.expense('الصيانة والإصلاح', <String>['تصليح', 'صيانه', 'ميكانيكي', 'بلومبي', 'reparation', 'repair', 'mecanicien', 'plombier', 'servis', 'bengkel', 'reparacion', 'mecanico', 'taller', 'tamir', 'tamirat', 'usta', 'baiki', 'مرمت', 'مستری', 'mechanic', 'reparatur', 'werkstatt', 'handwerker', 'conserto', 'manutenção', 'mecânico', 'oficina', 'encanador', 'riparazione', 'meccanico', 'idraulico', 'manutenzione', 'reparatie', 'garage', 'monteur', 'loodgieter', 'popravka', 'servis auta', 'majstor', 'vodoinstalater']),
    _Rule.expense('الأثاث والمنزل', <String>['اثاث', 'مفروشات', 'تجهيزات منزليه', 'meubles', 'furniture', 'mobilya', 'perabot', 'فرنیچر', 'möbel', 'ikea', 'móveis', 'móvel', 'mobili', 'arredamento', 'meubels', 'ikea', 'namještaj']),
    _Rule.expense('صدقة وتبرّعات', <String>['صدقه', 'تبرع', 'don', 'charity', 'donation', 'sadaqa', 'sedekah', 'infak', 'donasi', 'donativo', 'limosna', 'caridad', 'sadaka', 'bağış', 'derma', 'صدقہ', 'خیرات', 'عطیہ', 'sadqa', 'khairat', 'spende', 'spenden', 'doação', 'caridade', 'dízimo', 'donazione', 'beneficenza', 'donatie', 'goed doel', 'sadaka', 'donacija']),
    _Rule.expense('زكاة', <String>['زكاه', 'zakat', 'zekat', 'زکوٰۃ', 'zekat']),
    _Rule.expense('التأمين', <String>['تامين', 'assurance', 'insurance', 'asuransi', 'seguro', 'sigorta', 'kasko', 'insurans', 'takaful', 'بیمہ', 'انشورنس', 'versicherung', 'haftpflicht', 'krankenversicherung', 'seguro', 'assicurazione', 'rc auto', 'verzekering', 'zorgverzekering', 'autoverzekering', 'osiguranje']),
    _Rule.expense('الضرائب والرسوم', <String>['ضريبه', 'رسوم', 'طابع', 'impot', 'taxe', 'tax', 'fees', 'timbre', 'pajak', 'impuesto', 'impuestos', 'vergi', 'harç', 'cukai', 'ٹیکس', 'steuer', 'steuern', 'gebühr', 'gebühren', 'imposto', 'taxa', 'ipva', 'darf', 'tasse', 'imu', 'tari', 'bollo auto', 'f24', 'belasting', 'belastingdienst', 'heffing', 'porez', 'taksa']),
    _Rule.expense('الأقساط والقروض', <String>['قسط', 'قرض', 'loan', 'installment', 'mensualite', 'cicilan', 'kredit', 'paylater', 'prestamo', 'cuota', 'mensualidad', 'kredi', 'taksit', 'borç', 'pinjaman', 'ansuran', 'ptptn', 'darlehen', 'ratenzahlung', 'parcela', 'empréstimo', 'financiamento', 'consignado', 'rata', 'prestito', 'finanziamento', 'mutuo', 'lening', 'aflossing', 'afbetaling', 'rata', 'kredit rata', 'pozajmica']),
  ];
}

class _Rule {
  const _Rule.income(this.category, this.keywords) : type = TransactionType.income;
  const _Rule.expense(this.category, this.keywords)
      : type = TransactionType.expense;

  final String category;
  final List<String> keywords;
  final TransactionType type;
}
