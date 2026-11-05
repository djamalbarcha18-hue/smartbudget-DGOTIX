/// When debts are in more than one currency, the debts page lets the user
/// choose: one total in the base currency (others at today's rate), or one
/// line per currency with nothing converted. The choice is kept.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/debts/application/debt_totals_mode.dart';
import 'package:smartbudget/features/debts/application/debts_controller.dart';
import 'package:smartbudget/features/debts/domain/debt.dart';
import 'package:smartbudget/features/debts/presentation/debts_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Debt _debt(String id, String currency, DebtType type, double amount) => Debt(
      id: id,
      party: 'Friend $id',
      type: type,
      original: Money.fromDouble(amount, currency),
      paid: Money.fromDouble(0, currency),
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> open(WidgetTester tester, List<Debt> debts) async {
    SharedPreferences.setMockInitialValues(
        <String, Object>{'sb_base_currency': 'DZD'});
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        debtsProvider.overrideWith((ref) => Stream<List<Debt>>.value(debts)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
        home: const Scaffold(body: DebtsPage()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  final Finder chooser = find.byType(SegmentedButton<DebtTotalsMode>);

  testWidgets('debts all in the base currency: no choice to make',
      (WidgetTester tester) async {
    await open(tester, <Debt>[_debt('a', 'DZD', DebtType.lent, 1000)]);
    expect(chooser, findsNothing);
  });

  testWidgets('debts in two currencies: converted by default, with "≈"',
      (WidgetTester tester) async {
    await open(tester, <Debt>[
      _debt('a', 'DZD', DebtType.lent, 1000),
      _debt('b', 'EUR', DebtType.lent, 100),
    ]);
    expect(chooser, findsOneWidget);
    expect(find.textContaining('≈'), findsWidgets,
        reason: 'the euro debt shows what it is in dinars');
    expect(find.text('EUR'), findsNothing, reason: 'no per-currency row');
  });

  testWidgets('"by currency": one row per currency, nothing converted',
      (WidgetTester tester) async {
    await open(tester, <Debt>[
      _debt('a', 'DZD', DebtType.lent, 1000),
      _debt('b', 'EUR', DebtType.lent, 100),
      _debt('c', 'USD', DebtType.borrowed, 30),
    ]);

    await tester.tap(find.text('By currency'));
    await tester.pumpAndSettle();

    // One row per currency, and no converted figure.
    expect(find.text('DZD'), findsOneWidget);
    expect(find.text('EUR'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.textContaining('≈'), findsNothing);
    // The column titles are written once, not once per currency.
    expect(find.text('Owed to me'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);

    // And the choice is kept for next time.
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getString('sb_debt_totals_mode'), 'perCurrency');

    // Back to one total in the base currency.
    await tester.tap(find.text('In my currency'));
    await tester.pumpAndSettle();
    expect(find.text('EUR'), findsNothing);
    expect(find.textContaining('≈'), findsWidgets);
  });

  test('the choice is read back on the next start', () async {
    SharedPreferences.setMockInitialValues(
        <String, Object>{'sb_debt_totals_mode': 'perCurrency'});
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(debtTotalsModeProvider), DebtTotalsMode.converted);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(debtTotalsModeProvider), DebtTotalsMode.perCurrency);
  });
}
