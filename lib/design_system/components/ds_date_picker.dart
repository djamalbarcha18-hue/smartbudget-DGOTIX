import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'package:smartbudget/core/time/date_input.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Flutter's date picker with the app's date entry: the calendar keeps the
/// app language's month and weekday names, while a typed date is read as
/// year/month/day ("2026/10/25") in every language, as well as in the
/// language's own order (so "25/10/2026" still works in French).
///
/// Use it instead of `showDatePicker`. [initialDate] outside the range widens
/// the range instead of failing, so an old record can always be edited.
Future<DateTime?> showDsDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final DateTime initial = DateUtils.dateOnly(initialDate);
  final DateTime first = DateUtils.dateOnly(firstDate);
  final DateTime last = DateUtils.dateOnly(lastDate);
  final AppLocalizations l = AppLocalizations.of(context);
  final MaterialLocalizations m =
      await ymdMaterialLocalizations(Localizations.localeOf(context));
  if (!context.mounted) return null;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first.isAfter(initial) ? initial : first,
    lastDate: last.isBefore(initial) ? initial : last,
    fieldHintText: l.dateFieldHint,
    errorFormatText: l.dateInvalid,
    builder: (BuildContext context, Widget? child) => Localizations.override(
      context: context,
      delegates: <LocalizationsDelegate<Object>>[_Fixed(m)],
      child: child!,
    ),
  );
}

final Map<String, MaterialLocalizations> _cache =
    <String, MaterialLocalizations>{};

/// The language's Material localizations (English for a language Flutter
/// doesn't translate, as in the rest of the app), with typed dates read and
/// written as year/month/day.
@visibleForTesting
Future<MaterialLocalizations> ymdMaterialLocalizations(Locale locale) async {
  final Locale use = GlobalMaterialLocalizations.delegate.isSupported(locale)
      ? locale
      : const Locale('en');
  final String key = use.toString();
  final MaterialLocalizations? hit = _cache[key];
  if (hit != null) return hit;
  // Loads the language's date data and is what the rest of the app uses.
  await GlobalMaterialLocalizations.delegate.load(use);
  final String name = intl.DateFormat.localeExists(key)
      ? key
      : intl.DateFormat.localeExists(use.languageCode)
          ? use.languageCode
          : 'en';
  final String numbers = intl.NumberFormat.localeExists(name) ? name : 'en';
  final MaterialLocalizations made = getMaterialTranslation(
    use,
    intl.DateFormat.y(name),
    _YmdFormat(intl.DateFormat.yMd(name)),
    intl.DateFormat.yMMMd(name),
    intl.DateFormat.MMMEd(name),
    intl.DateFormat.yMMMMEEEEd(name),
    intl.DateFormat.yMMMM(name),
    intl.DateFormat.MMMd(name),
    intl.NumberFormat.decimalPattern(numbers),
    intl.NumberFormat('00', numbers),
  )!;
  return _cache[key] = made;
}

/// The compact date format behind the picker's text field: shows
/// "2026/10/25" and reads it back, then falls back to the language's own
/// order.
class _YmdFormat extends intl.DateFormat {
  _YmdFormat(this._native) : super('yyyy/MM/dd', 'en');

  final intl.DateFormat _native;

  @override
  String format(DateTime date) => DateInput.format(date);

  @override
  DateTime parseStrict(String inputString, [bool utc = false]) {
    final DateTime? ymd = DateInput.parse(inputString);
    if (ymd != null) return ymd;
    // The language's own order. Its pattern may hold direction marks that
    // nobody types (Arabic writes d/M/y with right-to-left marks), so both
    // sides lose them.
    final String plain = DateInput.clean(inputString);
    final String pattern = DateInput.clean(_native.pattern ?? '');
    try {
      return intl.DateFormat(pattern, _native.locale).parseStrict(plain);
    } on Object {
      // The picker turns a FormatException into "invalid date".
      throw FormatException('Not a date', inputString);
    }
  }
}

class _Fixed extends LocalizationsDelegate<MaterialLocalizations> {
  const _Fixed(this.value);

  final MaterialLocalizations value;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(value);

  @override
  bool shouldReload(_Fixed old) => old.value != value;
}
