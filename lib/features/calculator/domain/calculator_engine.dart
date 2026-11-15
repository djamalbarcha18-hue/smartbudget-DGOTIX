import 'package:flutter/foundation.dart';

/// A number with 15 fixed decimals held as an integer, so 0.1 + 0.2 is
/// exactly 0.3 and no NaN or Infinity can ever appear.
@immutable
class CalcNumber {
  const CalcNumber._(this.units);

  static const int scale = 15;
  static final BigInt _one = BigInt.from(10).pow(scale);

  /// Beyond this the result is refused as too large (1e60).
  static final BigInt _limit = BigInt.from(10).pow(60 + scale);

  /// The value times 10^15.
  final BigInt units;

  static final CalcNumber zero = CalcNumber._(BigInt.zero);

  bool get isZero => units == BigInt.zero;
  bool get isNegative => units < BigInt.zero;
  bool get tooLarge => units.abs() > _limit;

  /// From the typed text ("12", "-0.5", "3."); null when unreadable.
  static CalcNumber? parse(String text) {
    final RegExpMatch? m =
        RegExp(r'^(-?)(\d*)(?:\.(\d*))?$').firstMatch(text.trim());
    if (m == null) return null;
    final String whole = m[2]!.isEmpty ? '0' : m[2]!;
    String frac = m[3] ?? '';
    if (frac.length > scale) frac = frac.substring(0, scale);
    frac = frac.padRight(scale, '0');
    final BigInt v = BigInt.parse(whole) * _one + BigInt.parse(frac);
    return CalcNumber._(m[1] == '-' ? -v : v);
  }

  static BigInt _div(BigInt a, BigInt b) {
    // Rounded half away from zero.
    final bool neg = (a < BigInt.zero) != (b < BigInt.zero);
    final BigInt q = a.abs() * BigInt.two + b.abs();
    final BigInt r = q ~/ (b.abs() * BigInt.two);
    return neg ? -r : r;
  }

  CalcNumber operator +(CalcNumber o) => CalcNumber._(units + o.units);
  CalcNumber operator -(CalcNumber o) => CalcNumber._(units - o.units);
  CalcNumber operator *(CalcNumber o) =>
      CalcNumber._(_div(units * o.units, _one));

  /// Null when [o] is zero.
  CalcNumber? divide(CalcNumber o) =>
      o.isZero ? null : CalcNumber._(_div(units * _one, o.units));

  CalcNumber get negated => CalcNumber._(-units);

  /// [this] per cent.
  CalcNumber get percent => CalcNumber._(_div(units, BigInt.from(100)));

  /// Plain text with '.' as decimal mark, at most [decimals] decimals and no
  /// trailing zeros: "1234.5", "-0.3333333333".
  String plain({int decimals = 10}) {
    final BigInt step = BigInt.from(10).pow(scale - decimals);
    final BigInt r = _div(units, step);
    final bool neg = r < BigInt.zero;
    final String digits = r.abs().toString().padLeft(decimals + 1, '0');
    final String whole = digits.substring(0, digits.length - decimals);
    final String frac =
        digits.substring(digits.length - decimals).replaceFirst(RegExp(r'0+$'), '');
    final String body = frac.isEmpty ? whole : '$whole.$frac';
    return neg && body != '0' ? '-$body' : body;
  }

  @override
  bool operator ==(Object other) => other is CalcNumber && other.units == units;

  @override
  int get hashCode => units.hashCode;

  @override
  String toString() => plain();
}

enum CalcOp { add, subtract, multiply, divide }

enum CalcError { divideByZero, tooLarge }

/// Everything the screen shows; a new value after every key.
@immutable
class CalcState {
  const CalcState({
    this.accumulator,
    this.pending,
    this.entry,
    this.result = false,
    this.error,
    this.lastOp,
    this.lastOperand,
  });

  /// The left-hand value of the pending operation, or the last result.
  final CalcNumber? accumulator;
  final CalcOp? pending;

  /// What is being typed, as typed ("12.", "-0.5"); null when nothing is.
  final String? entry;

  /// The display shows a result of '='.
  final bool result;
  final CalcError? error;

  /// Repeating '=' repeats the last operation.
  final CalcOp? lastOp;
  final CalcNumber? lastOperand;

  static const CalcState initial = CalcState();
}

/// A pocket calculator: + − × ÷, per cent, sign, decimals, clear and
/// backspace, entered key by key. Pure: every key returns a new state.
///
/// Per cent follows the usual pocket-calculator rule: after + or − it is a
/// share of the first number (200 + 10% = 220), after × or ÷ it is the
/// number over 100 (200 × 10% = 20), and alone it divides by 100.
abstract final class Calculator {
  /// Significant digits that can be typed.
  static const int maxDigits = 15;

  static CalcState digit(CalcState s, int d) {
    assert(d >= 0 && d <= 9);
    if (s.error != null) s = CalcState.initial;
    final String current = s.result ? '' : (s.entry ?? '');
    final int typed = current.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (typed >= maxDigits) return s;
    String next;
    if (current == '0' || current == '-0') {
      next = current.replaceFirst('0', '$d');
    } else {
      next = '$current$d';
    }
    return _typing(s, next);
  }

  static CalcState decimalPoint(CalcState s) {
    if (s.error != null) s = CalcState.initial;
    final String current = s.result ? '' : (s.entry ?? '');
    if (current.contains('.')) return s;
    final String next = current.isEmpty || current == '-'
        ? '${current}0.'
        : '$current.';
    return _typing(s, next);
  }

  static CalcState _typing(CalcState s, String entry) => CalcState(
        accumulator: s.result ? null : s.accumulator,
        pending: s.result ? null : s.pending,
        entry: entry,
        lastOp: s.lastOp,
        lastOperand: s.lastOperand,
      );

  static CalcState op(CalcState s, CalcOp op) {
    if (s.error != null) return s;
    final CalcNumber? typed = s.entry == null ? null : CalcNumber.parse(s.entry!);
    // Two operators in a row: the second replaces the first.
    if (typed == null || s.result) {
      final CalcNumber left = s.accumulator ?? typed ?? CalcNumber.zero;
      return CalcState(accumulator: left, pending: op);
    }
    if (s.pending != null && s.accumulator != null) {
      final _Outcome o = _apply(s.accumulator!, s.pending!, typed);
      if (o.error != null) return CalcState(error: o.error);
      return CalcState(accumulator: o.value, pending: op);
    }
    return CalcState(accumulator: typed, pending: op);
  }

  static CalcState equals(CalcState s) {
    if (s.error != null) return s;
    final CalcNumber? typed = s.entry == null ? null : CalcNumber.parse(s.entry!);
    if (s.pending != null && s.accumulator != null) {
      final CalcNumber right = typed ?? s.accumulator!;
      return _result(s.accumulator!, s.pending!, right);
    }
    // '=' again: the last operation once more.
    if (s.result && s.lastOp != null && s.lastOperand != null &&
        s.accumulator != null) {
      return _result(s.accumulator!, s.lastOp!, s.lastOperand!);
    }
    final CalcNumber? value = typed ?? s.accumulator;
    if (value == null) return s;
    return CalcState(
        accumulator: value,
        result: true,
        lastOp: s.lastOp,
        lastOperand: s.lastOperand);
  }

  static CalcState _result(CalcNumber left, CalcOp op, CalcNumber right) {
    final _Outcome o = _apply(left, op, right);
    if (o.error != null) return CalcState(error: o.error);
    return CalcState(
        accumulator: o.value, result: true, lastOp: op, lastOperand: right);
  }

  static CalcState percent(CalcState s) {
    if (s.error != null) return s;
    final CalcNumber? typed = s.entry == null ? null : CalcNumber.parse(s.entry!);
    if (typed == null || s.result) {
      // Per cent of the shown result.
      final CalcNumber? v = s.accumulator;
      if (v == null) return s;
      return CalcState(accumulator: v.percent, result: true);
    }
    final CalcNumber value = switch (s.pending) {
      CalcOp.add || CalcOp.subtract when s.accumulator != null =>
        s.accumulator! * typed.percent,
      _ => typed.percent,
    };
    if (value.tooLarge) return const CalcState(error: CalcError.tooLarge);
    return CalcState(
        accumulator: s.accumulator,
        pending: s.pending,
        entry: value.plain(decimals: CalcNumber.scale));
  }

  static CalcState toggleSign(CalcState s) {
    if (s.error != null) return s;
    if (s.entry != null && !s.result) {
      final String e = s.entry!;
      return CalcState(
          accumulator: s.accumulator,
          pending: s.pending,
          entry: e.startsWith('-') ? e.substring(1) : '-$e');
    }
    final CalcNumber? v = s.accumulator;
    if (v == null) return const CalcState(entry: '-0');
    if (s.result || s.pending == null) {
      return CalcState(accumulator: v.negated, result: true);
    }
    // After an operator: start the next number as negative.
    return CalcState(accumulator: v, pending: s.pending, entry: '-0');
  }

  static CalcState backspace(CalcState s) {
    if (s.error != null) return CalcState.initial;
    if (s.result || s.entry == null) return s;
    String e = s.entry!.substring(0, s.entry!.length - 1);
    if (e == '-' || e.isEmpty) e = '';
    return CalcState(
        accumulator: s.accumulator,
        pending: s.pending,
        entry: e.isEmpty ? null : e);
  }

  static CalcState clear(CalcState s) => CalcState.initial;

  static _Outcome _apply(CalcNumber a, CalcOp op, CalcNumber b) {
    final CalcNumber? v = switch (op) {
      CalcOp.add => a + b,
      CalcOp.subtract => a - b,
      CalcOp.multiply => a * b,
      CalcOp.divide => a.divide(b),
    };
    if (v == null) return const _Outcome(error: CalcError.divideByZero);
    if (v.tooLarge) return const _Outcome(error: CalcError.tooLarge);
    return _Outcome(value: v);
  }

  /// The number to show in large type: what is typed, else the result or the
  /// left-hand value. '.' as decimal mark; the screen applies the user's style.
  static String display(CalcState s) {
    if (s.entry != null && !s.result) return s.entry!;
    return (s.accumulator ?? CalcNumber.zero).plain();
  }
}

class _Outcome {
  const _Outcome({this.value, this.error});
  final CalcNumber? value;
  final CalcError? error;
}

/// Writes a plain number ("-1234567.5", "12.") with the user's separators:
/// groups of three in the whole part, [decimal] as the decimal mark. Long
/// numbers switch to scientific notation so they always fit.
abstract final class CalcFormat {
  static const int maxChars = 16;

  static String format(String plain,
      {required String group, required String decimal}) {
    final bool neg = plain.startsWith('-');
    final String body = neg ? plain.substring(1) : plain;
    final int dot = body.indexOf('.');
    final String whole = dot < 0 ? body : body.substring(0, dot);
    final String frac = dot < 0 ? '' : body.substring(dot + 1);
    if (whole.length > maxChars - 1) return _scientific(plain, decimal);
    final StringBuffer g = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) g.write(group);
      g.write(whole[i]);
    }
    String out = g.toString();
    if (dot >= 0) {
      // Keep the whole number readable: cut decimals that don't fit.
      final int room = maxChars - whole.length - 1;
      final String shown = frac.length > room && room > 0
          ? frac.substring(0, room)
          : frac;
      out = '$out$decimal$shown';
    }
    return neg ? '-$out' : out;
  }

  static String _scientific(String plain, String decimal) {
    final double v = double.tryParse(plain) ?? 0;
    final String s = v.toStringAsExponential(8);
    final String mantissa = s.split('e').first.replaceFirst(RegExp(r'\.?0+$'), '');
    final String exp = s.split('e').last.replaceFirst('+', '');
    return '${mantissa.replaceAll('.', decimal)}e$exp';
  }
}
