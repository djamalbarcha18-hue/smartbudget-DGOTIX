import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/components/donut_chart.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/dashboard/application/dashboard_controller.dart';
import 'package:smartbudget/features/dashboard/presentation/income_expense_card.dart';
import 'package:smartbudget/features/transactions/domain/finance_calculator.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

List<CategoryTotal> _cats(String prefix, int n, {int top = 900000}) =>
    <CategoryTotal>[
      for (int i = 0; i < n; i++)
        CategoryTotal(
            category: '$prefix$i', amount: Money(top - i * 10000, 'EUR')),
    ];

/// Income and expenses the test can change, as a new month would.
final StateProvider<List<CategoryTotal>> _income =
    StateProvider<List<CategoryTotal>>((_) => _cats('In', 3));
final StateProvider<List<CategoryTotal>> _expense =
    StateProvider<List<CategoryTotal>>((_) => _cats('Ex', 9));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late AppLocalizations l;

  Future<ProviderContainer> pump(WidgetTester tester,
      {Locale locale = const Locale('en'),
      bool dark = false,
      double width = 400,
      List<CategoryTotal>? income,
      List<CategoryTotal>? expense}) async {
    tester.view.physicalSize = Size(width * 3, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      scopedIncomeCategoryTotalsProvider
          .overrideWith((Ref ref) => ref.watch(_income)),
      scopedExpenseCategoryTotalsProvider
          .overrideWith((Ref ref) => ref.watch(_expense)),
    ]);
    addTearDown(c.dispose);
    if (income != null) c.read(_income.notifier).state = income;
    if (expense != null) c.read(_expense.notifier).state = expense;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          extensions: <ThemeExtension<dynamic>>[
            dark ? DsColors.dark : DsColors.light,
            dark ? DsGlass.dark : DsGlass.light,
          ],
        ),
        home: const Scaffold(
            body: SingleChildScrollView(child: IncomeExpenseCard())),
      ),
    ));
    await tester.pumpAndSettle();
    l = await AppLocalizations.delegate.load(locale);
    return c;
  }

  // A category in the list of the page shown (its name can also be in the
  // donut's center once chosen).
  Finder row(String name) => find
      .descendant(of: find.byType(ListView), matching: find.text(name))
      .hitTestable();

  DonutChart donut(WidgetTester tester) =>
      tester.widget<DonutChart>(find.byType(DonutChart).hitTestable());

  testWidgets('income first; a tap on a tab or a swipe changes the page',
      (WidgetTester tester) async {
    await pump(tester);
    expect(find.text('In0'), findsOneWidget);
    await tester.tap(find.text(l.legendExpenses).first);
    await tester.pumpAndSettle();
    expect(find.text('Ex0'), findsOneWidget);
    // Swipe back (left to right in English) to income.
    await tester.drag(find.byType(PageView), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(donut(tester).centerBottom, l.legendIncome);
  });

  testWidgets('Arabic: the swipe follows the reading direction',
      (WidgetTester tester) async {
    await pump(tester, locale: const Locale('ar'));
    expect(donut(tester).centerBottom, l.legendIncome);
    // In right-to-left the next page comes from the left.
    await tester.drag(find.byType(PageView), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(donut(tester).centerBottom, l.legendExpenses);
  });

  testWidgets('a swipe that starts on the donut changes the page only',
      (WidgetTester tester) async {
    await pump(tester);
    await tester.drag(find.byType(DonutChart), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(donut(tester).centerBottom, l.legendExpenses);
    expect(donut(tester).selectedIndex, isNull);
  });

  testWidgets('a category tapped shows its value; again, the total',
      (WidgetTester tester) async {
    await pump(tester);
    final String total = donut(tester).centerTop!;
    await tester.tap(row('In1'));
    await tester.pumpAndSettle();
    expect(donut(tester).selectedIndex, 1);
    // The same compact amount (direction marks aside).
    String plain(String? v) =>
        (v ?? '').replaceAll(RegExp('[\u200E\u2067\u2069]'), '');
    expect(plain(donut(tester).selectedCenterTop),
        plain(MoneyFormatter.compact(const Money(890000, 'EUR'))));
    expect(donut(tester).selectedCenterBottom, 'In1');
    await tester.tap(row('In1'));
    await tester.pumpAndSettle();
    expect(donut(tester).selectedIndex, isNull);
    expect(donut(tester).centerTop, total);
  });

  testWidgets('expenses: six, then all, then six again',
      (WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.text(l.legendExpenses).first);
    await tester.pumpAndSettle();
    expect(find.text('Ex5'), findsOneWidget);
    expect(find.text('Ex6'), findsNothing);
    await tester.tap(find.text('${l.viewAll} (9)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ex8'), 40,
        scrollable: find
            .descendant(
                of: find.byType(PageView), matching: find.byType(Scrollable))
            .last);
    expect(find.text('Ex8'), findsOneWidget);
    await tester.tap(find.text(l.viewLess));
    await tester.pumpAndSettle();
    expect(find.text('Ex6'), findsNothing);
  });

  testWidgets(
      'many income categories: five, all on demand, scrolled inside a card '
      'that keeps its height', (WidgetTester tester) async {
    await pump(tester, income: _cats('In', 14));
    final double before = tester.getSize(find.byType(IncomeExpenseCard)).height;
    expect(find.text('In4'), findsOneWidget);
    expect(find.text('In5'), findsNothing);
    await tester.tap(find.text('${l.viewAll} (14)'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(IncomeExpenseCard)).height, before);
    final Finder list = find
        .descendant(
            of: find.byType(PageView), matching: find.byType(Scrollable))
        .at(1);
    await tester.scrollUntilVisible(find.text('In13'), 40, scrollable: list);
    expect(find.text('In13'), findsOneWidget);
    // Past the sixth, a category shows in "Other"'s colour, and choosing it
    // lights "Other" while the center says its own value.
    await tester.ensureVisible(find.text('In13'));
    await tester.pumpAndSettle();
    await tester.tap(row('In13'));
    await tester.pumpAndSettle();
    expect(donut(tester).selectedIndex, 6);
    expect(donut(tester).selectedCenterBottom, 'In13');
  });

  testWidgets('each page keeps its choice when the other is shown',
      (WidgetTester tester) async {
    await pump(tester);
    await tester.tap(row('In2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.legendExpenses).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.legendIncome).first);
    await tester.pumpAndSettle();
    expect(donut(tester).selectedIndex, 2);
  });

  testWidgets('a month with no income, then one with no expenses',
      (WidgetTester tester) async {
    final ProviderContainer c =
        await pump(tester, income: const <CategoryTotal>[]);
    expect(find.text(l.incomeNoneInPeriod), findsOneWidget);
    expect(find.byType(DonutChart), findsNothing); // no empty ring
    // The month changes above: both pages follow.
    c.read(_income.notifier).state = _cats('In', 2);
    c.read(_expense.notifier).state = const <CategoryTotal>[];
    await tester.pumpAndSettle();
    expect(find.text('In1'), findsOneWidget);
    await tester.tap(find.text(l.legendExpenses).first);
    await tester.pumpAndSettle();
    expect(find.text(l.expenseNoneInPeriod), findsOneWidget);
  });

  testWidgets('one category: a full ring, no "view all"',
      (WidgetTester tester) async {
    await pump(tester, income: _cats('In', 1));
    expect(find.text('100%'), findsOneWidget);
    expect(find.textContaining(l.viewAll), findsNothing);
  });

  for (final bool dark in <bool>[false, true]) {
    testWidgets('the chosen tab is plain to see (${dark ? 'dark' : 'light'})',
        (WidgetTester tester) async {
      await pump(tester, dark: dark);
      final Text chosen = tester.widget<Text>(find.text(l.legendIncome).first);
      final DefaultTextStyle style = tester.widget<DefaultTextStyle>(find
          .ancestor(
              of: find.text(l.legendIncome).first,
              matching: find.byType(DefaultTextStyle))
          .first);
      expect(chosen.data, l.legendIncome);
      expect(style.style.color, Colors.white);
      expect(style.style.fontWeight, FontWeight.w700);
      final DefaultTextStyle other = tester.widget<DefaultTextStyle>(find
          .ancestor(
              of: find.text(l.legendExpenses).first,
              matching: find.byType(DefaultTextStyle))
          .first);
      expect(other.style.fontWeight, FontWeight.w400);
      expect(tester.takeException(), isNull);
    });
  }

  test('white text reads on every income and expense colour', () {
    double contrast(Color c) => 1.05 / (c.computeLuminance() + 0.05);
    for (final DsColors c in <DsColors>[
      DsColors.light,
      DsColors.dark,
      DsColors.beige,
      DsColors.sage,
      DsColors.pomegranate,
      DsColors.black,
    ]) {
      expect(contrast(readableFill(c.income)), greaterThanOrEqualTo(4.5));
      expect(contrast(readableFill(c.expense)), greaterThanOrEqualTo(4.5));
    }
    // Already dark enough: unchanged.
    const Color deep = Color(0xFF1B5E20);
    expect(readableFill(deep), deep);
  });

  for (final double width in <double>[320, 1100]) {
    testWidgets('fits a ${width.toInt()}-wide screen',
        (WidgetTester tester) async {
      await pump(tester, width: width);
      expect(tester.takeException(), isNull);
      expect(find.byType(DonutChart), findsWidgets);
    });
  }
}
