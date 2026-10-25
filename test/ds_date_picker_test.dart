import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/components/ds_date_picker.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Opens the picker in [locale] and returns what OK gives: [typed] in the
/// text field, or a tap on [tapDay] in the calendar. Null while the dialog
/// stays open (an invalid date).
Future<DateTime?> _pick(
  WidgetTester tester,
  Locale locale, {
  String? typed,
  String? tapDay,
}) async {
  DateTime? result;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      ...AppLocalizations.localizationsDelegates,
      ...fallbackLocalizationsDelegates,
    ],
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () async => result = await showDsDatePicker(
            context,
            initialDate: DateTime(2026, 10, 1, 15, 30),
            firstDate: DateTime(2015),
            lastDate: DateTime(2100),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  final MaterialLocalizations m =
      MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)));
  if (typed != null) {
    await tester.tap(find.byTooltip(m.inputDateModeButtonLabel));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), typed);
  } else {
    await tester.tap(find.text(tapDay!));
  }
  await tester.pumpAndSettle();
  await tester.tap(find.text(m.okButtonLabel));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUpAll(LatinDigits.enforce);

  testWidgets('«2026/10/25» typed works in every language',
      (WidgetTester t) async {
    for (final Locale locale in AppLocalizations.supportedLocales) {
      expect(
          await _pick(t, locale, typed: '2026/10/25'), DateTime(2026, 10, 25),
          reason: '$locale');
    }
  });

  testWidgets('typed and tapped give the same calendar day',
      (WidgetTester t) async {
    for (final Locale locale in const <Locale>[
      Locale('ar'),
      Locale('en'),
      Locale('fr'),
      Locale('ja'),
    ]) {
      final DateTime? tapped = await _pick(t, locale, tapDay: '25');
      expect(tapped, DateTime(2026, 10, 25), reason: '$locale');
      expect(await _pick(t, locale, typed: '2026/10/25'), tapped);
    }
  });

  testWidgets('Arabic keyboard digits and direction marks',
      (WidgetTester t) async {
    for (final String s in <String>[
      '٢٠٢٦/١٠/٢٥',
      '\u200f2026\u200f/10\u200f/25',
      ' 2026/10/25 ',
    ]) {
      expect(
          await _pick(t, const Locale('ar'), typed: s), DateTime(2026, 10, 25),
          reason: s);
    }
  });

  testWidgets('the language’s own order still works', (WidgetTester t) async {
    expect(await _pick(t, const Locale('en'), typed: '10/25/2026'),
        DateTime(2026, 10, 25));
    expect(await _pick(t, const Locale('fr'), typed: '25/10/2026'),
        DateTime(2026, 10, 25));
    expect(await _pick(t, const Locale('de'), typed: '25.10.2026'),
        DateTime(2026, 10, 25));
    expect(await _pick(t, const Locale('ar'), typed: '25/10/2026'),
        DateTime(2026, 10, 25));
  });

  testWidgets('an impossible date shows the app’s message and keeps the dialog',
      (WidgetTester t) async {
    for (final Locale locale in const <Locale>[
      Locale('ar'),
      Locale('en'),
      Locale('ru'),
      Locale('zh'),
    ]) {
      final AppLocalizations l = await AppLocalizations.delegate.load(locale);
      for (final String s in <String>[
        '2026/02/30',
        '2026/13/01',
        '2026/10/00'
      ]) {
        expect(await _pick(t, locale, typed: s), isNull, reason: '$locale $s');
        expect(find.text(l.dateInvalid), findsOneWidget, reason: '$locale $s');
        // What was typed is still there to fix.
        expect(find.text(s), findsOneWidget);
        await t.tap(find.text(
            MaterialLocalizations.of(t.element(find.byType(DatePickerDialog)))
                .cancelButtonLabel));
        await t.pumpAndSettle();
      }
    }
  });

  testWidgets('leap day', (WidgetTester t) async {
    expect(await _pick(t, const Locale('en'), typed: '2024/02/29'),
        DateTime(2024, 2, 29));
    expect(await _pick(t, const Locale('en'), typed: '2026/02/29'), isNull);
  });

  testWidgets('the calendar keeps the language and the field the format',
      (WidgetTester t) async {
    await _pick(t, const Locale('ar'), typed: '2026/10/25');
    // Reopen and look: Arabic month names, a year/month/day field.
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.textContaining('أكتوبر'), findsWidgets);
    final MaterialLocalizations m =
        MaterialLocalizations.of(t.element(find.byType(DatePickerDialog)));
    await t.tap(find.byTooltip(m.inputDateModeButtonLabel));
    await t.pumpAndSettle();
    // The initial day, written year first.
    expect(find.text('2026/10/01'), findsOneWidget);
    expect(find.text('yyyy/mm/dd'), findsOneWidget);
  });

  testWidgets('a date outside the range widens it instead of failing',
      (WidgetTester t) async {
    DateTime? result;
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async => result = await showDsDatePicker(
            context,
            initialDate: DateTime(2010, 5, 1),
            firstDate: DateTime(2015),
            lastDate: DateTime(2016),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(result, DateTime(2010, 5, 1));
  });

  test('display follows the language, with Latin digits', () async {
    await ymdMaterialLocalizations(const Locale('ar')); // loads date data
    await ymdMaterialLocalizations(const Locale('en'));
    await ymdMaterialLocalizations(const Locale('fr'));
    final DateTime d = DateTime(2026, 10, 25);
    expect(dayText(const Locale('en'), d), 'Oct 25, 2026');
    expect(dayText(const Locale('fr'), d), '25 oct. 2026');
    expect(dayText(const Locale('ar'), d),
        allOf(contains('أكتوبر'), contains('2026')));
    // A language without date data falls back to English.
    expect(dayText(const Locale('ha'), d), isNotEmpty);
  });
}
