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

/// Turns short free text into transactions, entirely on the device: Arabic
/// (including Algerian darija), French and English keywords map to the
/// catalog categories; income is detected from income words or a leading "+";
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

    // Amount: the first number, with an optional k / ألف multiplier.
    final RegExpMatch? m = RegExp(
      r'(\d[\d\s.,]*\d|\d)\s*(k|K|ك|الف|ألف|آلاف|الاف|الآف|alf)?(?![\p{L}\d])',
      unicode: true,
    ).firstMatch(text);
    if (m == null) return null;
    final double? base = _number(m[1]!);
    if (base == null || base <= 0) return null;
    final double amount = m[2] == null ? base : base * 1000;
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

  /// "12,500" / "12.500" / "12 500" → 12500; "12,5" / "12.5" → 12.5.
  static double? _number(String raw) {
    String s = raw.replaceAll(RegExp(r'\s'), '');
    final RegExp grouped = RegExp(r'^\d{1,3}([.,]\d{3})+$');
    if (grouped.hasMatch(s) && !(s.contains('.') && s.contains(','))) {
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
      'ç': 'c', 'î': 'i', 'ï': 'i', 'ô': 'o', 'û': 'u', 'ù': 'u',
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
  ];

  static const List<String> _cashWords = <String>[
    'نقدا', 'نقد', 'كاش', 'cash', 'especes', 'espece', 'liquide',
  ];

  static const List<String> _incomeMarkers = <String>[
    'دخل', 'استلمت', 'قبضت', 'وصلني', 'ربحت', 'received', 'income', 'earned',
    'recu', 'encaisse',
  ];

  static const List<_Rule> _rules = <_Rule>[
    // ---- Income
    _Rule.income('راتب أساسي', <String>[
      'راتب', 'الشهريه', 'شهريه', 'معاش شهري', 'salaire', 'salary', 'paie',
      'paycheck', 'payroll',
    ]),
    _Rule.income('مكافآت وحوافز', <String>['مكافاه', 'حوافز', 'بريم', 'prime', 'bonus']),
    _Rule.income('معاش تقاعدي', <String>['تقاعد', 'retraite', 'pension']),
    _Rule.income('عمل حر', <String>['فريلانس', 'عمل حر', 'freelance', 'client']),
    _Rule.income('عمولات', <String>['عموله', 'commission']),
    _Rule.income('بيع أصول أو ممتلكات', <String>['بعت', 'بيع', 'vente', 'vendu', 'sold']),
    _Rule.income('استرداد أو تعويض', <String>[
      'استرجاع', 'تعويض', 'استرداد', 'remboursement', 'refund',
    ]),
    _Rule.income('منحة أو إعانة', <String>['منحه', 'اعانه', 'bourse', 'allocation', 'grant']),
    _Rule.income('إيجارات', <String>['مداخيل الكراء', 'rent income', 'loyer recu']),
    // ---- Expenses
    _Rule.expense('الطعام', <String>[
      'خضر', 'خضره', 'خضار', 'فواكه', 'فاكهه', 'لحم', 'دجاج', 'حوت', 'سمك',
      'خبز', 'حليب', 'بيض', 'سكر', 'زيت', 'بقاله', 'سوبرماركت', 'سوق',
      'مواد غذائيه', 'قضيان', 'courses', 'marche', 'epicerie', 'pain', 'lait',
      'supermarche', 'groceries', 'grocery', 'supermarket', 'bread', 'milk',
    ]),
    _Rule.expense('المطاعم', <String>[
      'مطعم', 'قهوه', 'كافيه', 'كافي', 'بيتزا', 'شاورما', 'كرانتيكا',
      'سندويش', 'سندويتش', 'غداء', 'عشاء', 'فطور', 'restaurant', 'cafe',
      'coffee', 'pizza', 'lunch', 'dinner', 'breakfast', 'fast food', 'snack',
      'burger', 'tacos',
    ]),
    _Rule.expense('النقل', <String>[
      'تاكسي', 'طاكسي', 'حافله', 'باص', 'ترامواي', 'ميترو', 'مترو', 'قطار',
      'نقل', 'كورسا', 'taxi', 'bus', 'tram', 'metro', 'train', 'uber', 'yassir',
      'heetch', 'transport',
    ]),
    _Rule.expense('الوقود', <String>[
      'بنزين', 'وقود', 'مازوت', 'ليصانص', 'essence', 'carburant', 'gasoil',
      'diesel', 'fuel', 'petrol', 'gasoline',
    ]),
    _Rule.expense('السكن', <String>['كراء', 'ايجار', 'loyer', 'rent']),
    _Rule.expense('الفواتير', <String>[
      'فاتوره', 'كهرباء', 'ضو', 'ماء', 'غاز', 'سونلغاز', 'سيال', 'facture',
      'electricite', 'sonelgaz', 'seaal', 'electricity', 'water bill', 'bill',
    ]),
    _Rule.expense('الاتصالات والإنترنت', <String>[
      'انترنت', 'فليكسي', 'رصيد', 'هاتف', 'موبيليس', 'جيزي', 'اوريدو',
      'اتصالات الجزائر', 'idoom', 'flexy', 'internet', 'wifi', 'phone',
      'mobile', 'recharge', 'mobilis', 'djezzy', 'ooredoo', 'forfait',
    ]),
    _Rule.expense('الصحة', <String>[
      'صيدليه', 'دواء', 'ادويه', 'طبيب', 'دكتور', 'مستشفى', 'عياده',
      'تحاليل', 'اشعه', 'pharmacie', 'medecin', 'docteur', 'medicament',
      'clinique', 'pharmacy', 'doctor', 'medicine', 'clinic', 'dentist',
      'dentiste',
    ]),
    _Rule.expense('التعليم', <String>[
      'مدرسه', 'جامعه', 'دروس', 'كتب', 'كتاب', 'كورس', 'دوره تدريبيه', 'كراريس', 'ادوات مدرسيه', 'تسجيل',
      'ecole', 'cours', 'livres', 'fournitures', 'school', 'tuition', 'books',
      'course',
    ]),
    _Rule.expense('الأطفال والعائلة', <String>[
      'حفاظات', 'حليب اطفال', 'روضه', 'حضانه', 'creche', 'couches', 'diapers',
      'kids', 'baby',
    ]),
    _Rule.expense('الملابس', <String>[
      'ملابس', 'حذاء', 'صباط', 'سروال', 'قميص', 'جاكيت', 'vetements',
      'chaussures', 'clothes', 'shoes', 'jacket',
    ]),
    _Rule.expense('التسوق', <String>['تسوق', 'مشتريات', 'jumia', 'amazon', 'shopping', 'aliexpress']),
    _Rule.expense('الترفيه', <String>['سينما', 'ترفيه', 'نزهه', 'cinema', 'sortie', 'games', 'concert']),
    _Rule.expense('الاشتراكات', <String>[
      'اشتراك', 'netflix', 'spotify', 'youtube', 'abonnement', 'subscription',
      'shahid', 'شاهد',
    ]),
    _Rule.expense('الرياضة واللياقة', <String>['جيم', 'نادي رياضي', 'رياضه', 'gym', 'salle de sport', 'fitness']),
    _Rule.expense('السفر', <String>['سفر', 'فندق', 'طياره', 'طيران', 'hotel', 'flight', 'voyage', 'travel', 'billet avion']),
    _Rule.expense('الصيانة والإصلاح', <String>['تصليح', 'صيانه', 'ميكانيكي', 'بلومبي', 'reparation', 'repair', 'mecanicien', 'plombier']),
    _Rule.expense('الأثاث والمنزل', <String>['اثاث', 'مفروشات', 'تجهيزات منزليه', 'meubles', 'furniture']),
    _Rule.expense('صدقة وتبرّعات', <String>['صدقه', 'تبرع', 'don', 'charity', 'donation', 'sadaqa']),
    _Rule.expense('زكاة', <String>['زكاه', 'zakat']),
    _Rule.expense('التأمين', <String>['تامين', 'assurance', 'insurance']),
    _Rule.expense('الضرائب والرسوم', <String>['ضريبه', 'رسوم', 'طابع', 'impot', 'taxe', 'tax', 'fees', 'timbre']),
    _Rule.expense('الأقساط والقروض', <String>['قسط', 'قرض', 'loan', 'installment', 'mensualite']),
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
