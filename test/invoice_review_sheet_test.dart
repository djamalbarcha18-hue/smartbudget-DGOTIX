import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';
import 'package:smartbudget/features/receipts/presentation/invoice_review_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What the model returns for a small grocery receipt; [line2Total] lets a
/// test inject a misread amount.
Map<String, dynamic> receipt({String line2Total = '3.60'}) => <String, dynamic>{
      'r': true,
      'inv': 'GM-2026-004582',
      'dt': '2026-09-05',
      'cur': 'USD',
      'sym': 'US\$',
      'sup': 'GlobalMart',
      'cus': '',
      'cat': 'الطعام',
      'it': <Map<String, dynamic>>[
        <String, dynamic>{'n': 'Milk 1L', 'q': '2', 'u': '2.49', 't': '4.98', 'c': 0.98},
        <String, dynamic>{'n': 'Bread', 'q': '3', 'u': '1.20', 't': line2Total, 'c': 0.96},
        <String, dynamic>{'n': 'Coffee 250g', 'q': '1', 'u': '6.50', 't': '6.50', 'c': 0.97},
      ],
      'sub': '15.08',
      'dis': '0.75',
      'tax': '1.15',
      'tot': '15.48',
      'paid': '20.00',
      'due': '',
    };

ThemeData testTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const <ThemeExtension<dynamic>>[DsColors.dark, DsGlass.dark],
    );

Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: testTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
    );

void main() {
  final DateTime today = DateTime(2026, 10, 2);

  testWidgets('a verified invoice shows its fields and no warnings',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final InvoiceReading r = InvoiceAnalyzer.analyze(receipt(), today: today);
    expect(r.level(), ReviewLevel.verified);
    await tester.pumpWidget(host(InvoiceReviewSheet(
      reading: r,
      timings: const ScanTimings(prepare: 12, reading: 2400, model: 2100, checks: 3),
    )));
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('GM-2026-004582'), findsOneWidget);
    expect(find.text('GlobalMart'), findsOneWidget);
    expect(find.text('Milk 1L'), findsOneWidget);
    expect(find.text('Items (3)'), findsOneWidget);
    expect(find.text('Read in 2.4 s'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a misread line is flagged, and fixing it verifies the invoice',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final InvoiceReading r =
        InvoiceAnalyzer.analyze(receipt(line2Total: '5.60'), today: today);
    await tester.pumpWidget(host(InvoiceReviewSheet(
      reading: r,
      timings: const ScanTimings(),
      duplicate: true,
    )));
    expect(find.text('Needs review'), findsOneWidget);
    expect(find.text('A calculation difference was found in one of the products.'),
        findsOneWidget);
    expect(find.text('This invoice may be a duplicate.'), findsOneWidget);

    // Open the flagged line and correct its total.
    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();
    expect(find.text('Edit line'), findsOneWidget);
    final Finder totalField = find.byType(TextField).at(3);
    await tester.enterText(totalField, '3.60');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('A calculation difference was found in one of the products.'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a correct invoice with only "\$" says to check the currency',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // "$" alone fits several dollars: the reading is not verified, and the
    // sheet says why instead of showing "Needs review" with no reason.
    final InvoiceReading r = InvoiceAnalyzer.analyze(
        <String, dynamic>{...receipt(), 'sym': r'$'},
        today: today);
    expect(r.level(), ReviewLevel.warning);
    await tester.pumpWidget(host(InvoiceReviewSheet(reading: r, timings: const ScanTimings())));
    expect(
        find.text("Check the currency: USD was inferred, as the receipt doesn't show it clearly."),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic layout renders without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final InvoiceReading r =
        InvoiceAnalyzer.analyze(receipt(line2Total: '5.60'), today: today);
    await tester.pumpWidget(host(
      InvoiceReviewSheet(reading: r, timings: const ScanTimings()),
      locale: const Locale('ar'),
    ));
    expect(find.text('تحتاج مراجعة'), findsOneWidget);
    expect(find.text('تم اكتشاف اختلاف حسابي في أحد المنتجات.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
