import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/money/amount_input.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/time/date_input.dart';

/// What a bank or wallet message says: one payment or one deposit.
class BankMessage {
  const BankMessage({
    required this.amount,
    required this.income,
    this.currency,
    this.date,
    this.merchant,
  });

  final double amount;

  /// Money in (a deposit, a transfer received, a refund) rather than out.
  final bool income;

  /// ISO code when the message names one clearly («SAR», «د.ج», «€»).
  final String? currency;

  /// The day the message gives, when it gives one.
  final DateTime? date;

  /// Where the money went or came from, when the message says.
  final String? merchant;
}

/// Reads a bank SMS or notification text the user chose to share with the
/// app. Nothing is read on its own: only the text handed over, on the device.
///
/// The amount is the one next to a currency (or after "amount"), never the
/// remaining balance, a masked card number, a date or a one-time code.
abstract final class BankMessageParser {
  static BankMessage? parse(String text, {required DateTime today}) {
    String t = _clean(text);
    if (t.isEmpty || _otp.hasMatch(t)) return null;
    // "Rs. 500": the abbreviation's dot is not the end of a sentence.
    t = t.replaceAllMapped(_abbrevDot, (Match m) => '${m[1] ?? m[2]} ');

    final String lower = _words(t);
    final int inAt = _firstIndex(lower, _incomeWords);
    final int outAt = _firstIndex(lower, _expenseWords);
    // On a tie the longer income word holds the expense one («승인취소»,
    // a cancelled payment, starts with «승인», a payment).
    final bool income = inAt >= 0 && (outAt < 0 || inAt <= outAt);
    final bool spoken = inAt >= 0 || outAt >= 0;

    final DateTime? date = _date(t, today);

    ({double amount, String? currency})? found;
    for (final String segment in t.split(_segments)) {
      // What comes after «balance» is the balance, not the payment.
      final RegExpMatch? bal = _balance.firstMatch(segment.toLowerCase());
      final String s =
          (bal == null ? segment : segment.substring(0, bal.start)).trim();
      if (s.isEmpty) continue;
      found = _amount(_withoutNoise(s), spoken: spoken);
      if (found != null) break;
    }
    if (found == null || found.amount <= 0) return null;
    return BankMessage(
      amount: found.amount,
      income: income,
      currency: found.currency,
      date: date,
      merchant: _merchant(t, income: income),
    );
  }

  /// Whether [text], typed or pasted, reads like a whole bank message rather
  /// than a short quick-entry line («قهوة 35»): it is long and has a
  /// balance, a masked card, or a payment word with an amount next to a
  /// currency.
  static bool looksLikeMessage(String text) {
    final String t = _clean(text);
    // Chinese, Japanese and Korean say as much in far fewer letters.
    final int min = RegExp(_cjk).hasMatch(t) ? 16 : 40;
    if (t.length < min || _otp.hasMatch(t)) return false;
    final String lower = _words(t);
    if (_balance.hasMatch(lower) || RegExp(r'[*xX#]{2,}\s*\d').hasMatch(t)) {
      return true;
    }
    final bool spoken = _firstIndex(lower, _incomeWords) >= 0 ||
        _firstIndex(lower, _expenseWords) >= 0;
    return spoken &&
        t.split(_segments).any(
            (String s) => _amount(_withoutNoise(s), spoken: false) != null);
  }

  /// Whether [text] («Credit», «إيداع», «入金») says money came in (true)
  /// or went out (false); null when it says neither.
  static bool? directionOf(String text) {
    final String lower = _words(_clean(text));
    final int inAt = _firstIndex(lower, _incomeWords);
    final int outAt = _firstIndex(lower, _expenseWords);
    if (inAt < 0 && outAt < 0) return null;
    return inAt >= 0 && (outAt < 0 || inAt <= outAt);
  }

  /// [text] with Latin digits (also from full-width and Devanagari ones).
  static String digits(String text) => _clean(text);

  /// Latin digits (also full-width and Devanagari ones), plain colons.
  static String _clean(String text) {
    final StringBuffer b = StringBuffer();
    for (final int u in LatinDigits.normalize(text).codeUnits) {
      if (u >= 0xFF10 && u <= 0xFF19) {
        b.writeCharCode(0x30 + u - 0xFF10); // ０-９
      } else if (u >= 0x0966 && u <= 0x096F) {
        b.writeCharCode(0x30 + u - 0x0966); // ०-९
      } else if (u == 0xFF1A) {
        b.write(':');
      } else if (u == 0xFF0E) {
        b.write('.');
      } else {
        b.writeCharCode(u);
      }
    }
    return DateInput.clean(b.toString());
  }

  /// Lower case for the word lists, with app names that hold a payment word
  /// blanked out («支付宝», Alipay, is not a payment in itself).
  static String _words(String t) => t.toLowerCase().replaceAll('支付宝', '   ');

  static const String _cjk = r'[\u3040-\u30FF\u3400-\u9FFF\uAC00-\uD7AF]';

  // ---- Amount ---------------------------------------------------------------

  static final RegExp _number =
      RegExp(r'(?<![\d.,])\d{1,3}(?:[,.  ]\d{3})+(?:[.,]\d{1,3})?(?![\d])'
          r'|(?<![\d.,])\d+(?:[.,]\d{1,3})?(?![\d])');

  static ({double amount, String? currency})? _amount(String s,
      {required bool spoken}) {
    final List<RegExpMatch> numbers = _number.allMatches(s).toList();
    if (numbers.isEmpty) return null;
    // Next to a currency, before or after.
    for (final RegExpMatch n in numbers) {
      final String before = s.substring(0, n.start).trimRight();
      final String after = s.substring(n.end).trimLeft();
      final String? code = _currencyAtEnd(before) ??
          _currencyAtStart(after) ??
          // «R120.50»: the rand's lone «R» only when glued to the amount.
          (RegExp(r'(?<![\p{L}])R$', unicode: true)
                  .hasMatch(s.substring(0, n.start))
              ? 'ZAR'
              : null);
      if (code != null) {
        final double? v = _value(n[0]!, code.isEmpty ? null : code);
        if (v != null) return (amount: v, currency: code.isEmpty ? null : code);
      }
    }
    // After "amount", "مبلغ", "montant"…
    final String lower = s.toLowerCase();
    for (final RegExpMatch n in numbers) {
      final String before = lower
          .substring(0, n.start)
          .replaceFirst(RegExp(r'[\s:=-]+$'), '');
      if (_amountWords.any(before.endsWith)) {
        final double? v = _value(n[0]!, null);
        if (v != null) return (amount: v, currency: null);
      }
    }
    // A payment or deposit message with a single number in it.
    if (spoken && numbers.length == 1) {
      final double? v = _value(numbers.single[0]!, null);
      if (v != null) return (amount: v, currency: null);
    }
    return null;
  }

  /// «2.500 ALL» is two thousand five hundred: one separator before exactly
  /// three digits groups thousands, unless the currency has three decimals
  /// («KWD 12.500»).
  static double? _value(String raw, String? code) {
    final RegExpMatch? m = RegExp(r'^(\d{1,3})[.,](\d{3})$').firstMatch(raw);
    if (m != null) {
      final int decimals = code == null ? 2 : Currencies.byCode(code).decimals;
      if (decimals != 3) return double.parse('${m[1]}${m[2]}');
    }
    return AmountInput.parse(raw);
  }

  /// Masked cards and accounts, long references, dates and times: numbers
  /// that are never the amount.
  static String _withoutNoise(String s) => s
      .replaceAll(RegExp(r'[*xX#]{2,}\s*\d+'), ' ')
      .replaceAll(RegExp(r'\b\d{7,}\b'), ' ')
      .replaceAll(_dateCjk, ' ')
      .replaceAll(_dateYmd, ' ')
      .replaceAll(_dateDmy, ' ')
      .replaceAll(_dateNamed, ' ')
      .replaceAll(RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?\b'), ' ');

  /// '' for a currency word that doesn't say which currency («ريال»).
  static String? _currencyAtEnd(String before) {
    for (final (String token, String code) in _currencyTokens) {
      if (before.endsWith(token) &&
          (before.length == token.length ||
              !_isLetter(
                  before.codeUnitAt(before.length - token.length - 1)))) {
        return code;
      }
    }
    return null;
  }

  static String? _currencyAtStart(String after) {
    for (final (String token, String code) in _currencyTokens) {
      if (after.startsWith(token) &&
          (after.length == token.length ||
              !_isLetter(after.codeUnitAt(token.length)))) {
        return code;
      }
    }
    return null;
  }

  /// A letter that would make the currency mark part of a longer word.
  /// Chinese, Japanese and Korean have no spaces, so no word edges either.
  static bool _isLetter(int c) {
    final String ch = String.fromCharCode(c);
    return !RegExp(_cjk).hasMatch(ch) && _letter.hasMatch(ch);
  }

  static final RegExp _letter = RegExp(r'[\p{L}\p{M}]', unicode: true);

  /// Currency marks, longest first: ISO codes, symbols and common
  /// abbreviations («SR», «DA», «د.ج»), and a few words.
  static final List<(String, String)> _currencyTokens = () {
    final Map<String, String> m = <String, String>{};
    for (final Currency c in Currencies.all) {
      m.putIfAbsent(c.code, () => c.code);
      final String sym = c.symbol;
      // A lone letter ("R", "L") is too common to be a currency mark.
      if (sym.length > 1 || !RegExp(r'[A-Za-z]').hasMatch(sym)) {
        m[sym] = m.containsKey(sym) && m[sym] != c.code ? '' : c.code;
      }
    }
    m['\$'] = 'USD';
    m.addAll(const <String, String>{
      'SR': 'SAR',
      'QR': 'QAR',
      'KD': 'KWD',
      'BD': 'BHD',
      'RO': 'OMR',
      'AED': 'AED',
      'Dhs': 'AED',
      'DA': 'DZD',
      'دج': 'DZD',
      'DT': 'TND',
      'DH': 'MAD',
      'MAD': 'MAD',
      'EGP': 'EGP',
      'LE': 'EGP',
      'Rs': '',
      'INR': 'INR',
      'PKR': 'PKR',
      'دولار': 'USD',
      'يورو': 'EUR',
      'euros': 'EUR',
      'euro': 'EUR',
      'dollars': 'USD',
      'ريال': '',
      'دينار': '',
      'درهم': '',
      'جنيه': '',
      'ليرة': '',
      'руб': 'RUB',
      'руб.': 'RUB',
      'TL': 'TRY',
      'Ksh': 'KES',
      'Kshs': 'KES',
      'TSh': 'TZS',
      'Tsh': 'TZS',
      'USh': 'UGX',
      'रु': '',
      'रुपये': '',
      'روپے': '',
      'ریال': 'IRR',
      'تومان': '',
      '元': '',
      '人民币': 'CNY',
      'RMB': 'CNY',
      '港元': 'HKD',
      '港币': 'HKD',
      '新台币': 'TWD',
      '台币': 'TWD',
      '円': 'JPY',
      '원': 'KRW',
    });
    final List<(String, String)> list = <(String, String)>[
      for (final MapEntry<String, String> e in m.entries) (e.key, e.value),
    ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return list;
  }();

  // ---- Date -----------------------------------------------------------------

  static final RegExp _dateYmd =
      RegExp(r'\b(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\b');
  static final RegExp _dateDmy =
      RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})\b');
  /// «2026年10月24日», «10月24日», «2026년 10월 24일».
  static final RegExp _dateCjk = RegExp(
      r'(?:(\d{4})\s*[年년]\s*)?(\d{1,2})\s*[月월]\s*(\d{1,2})\s*[日일]');
  static final RegExp _dateNamed = RegExp(
      r'\b(\d{1,2})[-\s]?(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?[-\s,]*(\d{4}|\d{2})?\b',
      caseSensitive: false);
  static const List<String> _months = <String>[
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  static DateTime? _date(String t, DateTime today) {
    DateTime? d;
    final RegExpMatch? ymd = _dateYmd.firstMatch(t);
    final RegExpMatch? dmy = _dateDmy.firstMatch(t);
    final RegExpMatch? named = _dateNamed.firstMatch(t);
    final RegExpMatch? cjk = _dateCjk.firstMatch(t);
    if (cjk != null) {
      d = DateInput.dateOf(cjk[1] == null ? today.year : int.parse(cjk[1]!),
          int.parse(cjk[2]!), int.parse(cjk[3]!));
    } else if (ymd != null) {
      d = DateInput.dateOf(
          int.parse(ymd[1]!), int.parse(ymd[2]!), int.parse(ymd[3]!));
    } else if (dmy != null) {
      int day = int.parse(dmy[1]!);
      int month = int.parse(dmy[2]!);
      if (month > 12 && day <= 12) (day, month) = (month, day); // 10/25/2026
      d = DateInput.dateOf(_year(dmy[3]!), month, day);
    } else if (named != null) {
      final int month = _months.indexOf(named[2]!.toLowerCase()) + 1;
      d = DateInput.dateOf(named[3] == null ? today.year : _year(named[3]!),
          month, int.parse(named[1]!));
    }
    // Never a day still to come.
    if (d == null || d.isAfter(today.add(const Duration(days: 1)))) return null;
    return d;
  }

  static int _year(String y) =>
      y.length == 2 ? 2000 + int.parse(y) : int.parse(y);

  // ---- Merchant -------------------------------------------------------------

  static String? _merchant(String t, {required bool income}) {
    final List<String> markers = income
        ? const <String>[
            ' from ',
            ' de la part de ',
            ' من ',
            ' von ',
            ' от ',
            ' van ',
            ' kutoka ',
            ' nga ',
          ]
        : const <String>[
            ' at ',
            ' @ ',
            ' chez ',
            ' bei ',
            ' لدى ',
            ' عند ',
            ' في ',
            ' в ',
            ' en ',
            ' à ',
            ' to ',
            ' إلى ',
            ' bij ',
            ' kwa ',
            ' në ',
            'ご利用先:',
            '利用先:',
            '利用店:',
          ];
    final String padded = ' ${t.replaceAll('\n', ' ')} ';
    final String lower = padded.toLowerCase();
    for (final String m in markers) {
      int from = 0;
      while (true) {
        final int i = lower.indexOf(m, from);
        if (i < 0) break;
        from = i + m.length;
        String rest = padded.substring(from);
        final int cut = rest.indexOf(_merchantEnd);
        if (cut >= 0) rest = rest.substring(0, cut);
        rest = rest.trim();
        if (rest.length > 40) rest = rest.substring(0, 40).trim();
        // A name has letters and isn't a currency or a card.
        if (RegExp(r'\p{L}{2,}', unicode: true).hasMatch(rest) &&
            !_balance.hasMatch(rest.toLowerCase()) &&
            _currencyAtStart(rest) == null &&
            !RegExp(r'^(your|you|card|account|a/c|بطاقت|حساب)',
                    caseSensitive: false)
                .hasMatch(rest)) {
          return rest;
        }
      }
    }
    return null;
  }

  static final RegExp _merchantEnd = RegExp(
      r'[.,;:\n|()、。，]|\s(on|le|am|el|il|op|tarehe|بتاريخ|بقيمة|يوم|ref|using|via|with|avec)\s'
      r'|\s(ご利用|利用|金額)|\d',
      caseSensitive: false);

  // ---- Words ----------------------------------------------------------------

  static int _firstIndex(String lower, List<String> words) {
    int best = -1;
    for (final String w in words) {
      final int i = lower.indexOf(w);
      if (i >= 0 && (best < 0 || i < best)) best = i;
    }
    return best;
  }

  static const List<String> _incomeWords = <String>[
    'credited',
    'credit of',
    'deposit',
    'received',
    'refund',
    'salary',
    'تم إيداع',
    'إيداع',
    'ايداع',
    'وارد',
    'استلام',
    'استرداد',
    'راتب',
    'crédit',
    'crédité',
    'reçu',
    'virement reçu',
    'remboursement',
    'gutschrift',
    'eingang',
    'зачисление',
    'поступление',
    'зачислено',
    'yatırıldı',
    'gelen',
    'masuk',
    'diterima',
    'recibido',
    'abono',
    'recebido',
    'accredito',
    'bijgeschreven',
    'ontvangen',
    'storting',
    'salaris',
    'terugbetaling',
    'gekrediteer',
    'ontvang',
    'deposito',
    'inbetaling',
    'uplata',
    'uplaćen',
    'priliv',
    'kredituar',
    'depozit',
    'marrë',
    'rrogë',
    'pagë',
    'umepokea',
    'imewekwa',
    'mshahara',
    'imeingizwa',
    'an saka',
    'an karɓa',
    'an karba',
    'albashi',
    'जमा',
    'प्राप्त',
    'वेतन',
    'جمع ہو',
    'جمع کی',
    'جمع کیے',
    'موصول',
    'تنخواہ',
    'واریز',
    'دریافت',
    'بستانکار',
    '入账',
    '存入',
    '转入',
    '工资',
    '退款',
    '到账',
    '收入',
    '收款',
    '入金',
    '給与',
    '返金',
    '입금',
    '급여',
    '환불',
    '승인취소',
    '결제취소',
  ];

  static const List<String> _expenseWords = <String>[
    'debited',
    'debit',
    'purchase',
    'paid',
    'spent',
    'withdrawal',
    'withdrawn',
    'payment',
    'pos ',
    'خصم',
    'شراء',
    'سحب',
    'دفع',
    'مدين',
    'عملية شراء',
    'achat',
    'paiement',
    'retrait',
    'débit',
    'débité',
    'списание',
    'покупка',
    'оплата',
    'снятие',
    'harcama',
    'çekim',
    'pembelian',
    'tarik',
    'compra',
    'pago',
    'retiro',
    'pagamento',
    'acquisto',
    'zahlung',
    'abhebung',
    'lastschrift',
    'afgeschreven',
    'betaling',
    'aankoop',
    'opname',
    'betaald',
    'gedebiteer',
    'onttrekking',
    'betaal',
    'isplata',
    'kupovina',
    'plaćanje',
    'placanje',
    'terećen',
    'zadužen',
    'podizanje',
    'debituar',
    'pagesë',
    'blerje',
    'tërheq',
    'umetuma',
    'umelipa',
    'imetolewa',
    'umetoa',
    'malipo',
    'ununuzi',
    'an cire',
    'an biya',
    'sayayya',
    'डेबिट',
    'निकाल',
    'निकासी',
    'भुगतान',
    'खरीद',
    'खर्च',
    'ڈیبٹ',
    'نکالے',
    'نکلوائے',
    'ادائیگی',
    'خریداری',
    'کٹوتی',
    'برداشت',
    'خرید',
    'پرداخت',
    'بدهکار',
    '支出',
    '消费',
    '支付',
    '扣款',
    '取款',
    '转出',
    '付款',
    '扣费',
    '出金',
    '引落',
    '引き落とし',
    'ご利用',
    '支払',
    '決済',
    '購入',
    '출금',
    '승인',
    '결제',
    '사용',
    '지출',
  ];

  static const List<String> _amountWords = <String>[
    'amount',
    'amt',
    'montant',
    'مبلغ',
    'بمبلغ',
    'بقيمة',
    'قيمة',
    'сумма',
    'tutar',
    'jumlah',
    'betrag',
    'importe',
    'valor',
    'importo',
    'bedrag',
    'iznos',
    'shuma',
    'kiasi',
    'adadin',
    'राशि',
    '金额',
    '金額',
    '금액',
  ];

  static final RegExp _balance = RegExp(
      r'balance|\bbal\b|avl|available|الرصيد|رصيدك|رصيد|solde|saldo|bakiye|'
      r'баланс|остаток|kontostand|limit|stanje|raspoloživ|gjendj|bilanc|'
      r'salio|ragowa|शेष|बैलेंस|بیلنس|بقایا|مانده|موجودی|余额|残高|利用可能|잔액');

  static final RegExp _otp = RegExp(
      r'\botp\b|one[- ]time|verification code|code de vérification|'
      r'رمز التحقق|كلمة المرور لمرة|код подтверждения|doğrulama kodu|'
      r'verificatiecode|eenmalige|verifikacijski|jednokratn|kodi i verifikimit|'
      r'nambari ya uthibitisho|ओटीपी|सत्यापन कोड|تصدیقی کوڈ|کد تایید|رمز پویا|'
      r'رمز یکبار|验证码|動態|認証コード|ワンタイム|인증번호',
      caseSensitive: false);

  /// Lines, «;», «|», «،», the full stops and commas of other scripts
  /// («。», «，», «।», «۔»), and sentence ends: a dot before a space, or a dot
  /// glued to the next sentence when a single-line field dropped the line
  /// break («2024.Available»). Not the dot inside «ر.س» or «120.50».
  static final RegExp _segments =
      RegExp(r'[\n;|،。，；！।۔]|\.\s+|(?<=[a-z0-9])\.(?=[A-Z])');

  static final RegExp _abbrevDot = RegExp(
      r'\b(Rs|Dhs|SR|QR|KD|BD|RO|Rp|руб)\.\s*|(रु)\.\s*',
      caseSensitive: false);
}
