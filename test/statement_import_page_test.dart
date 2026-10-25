import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/statement_import/presentation/statement_import_page.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const String statement = '''
Transaction Date,Description,Debit,Credit,Balance
03/10/2026,SALARY ACME LTD,,"8,500.00","13,500.00"
14/10/2026,CARREFOUR,"1,240.75",,"12,259.25"
not a date,???,5.00,,
''';

  Future<ProviderContainer> pump(WidgetTester tester, String csv) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    final GoRouter router = GoRouter(
      initialLocation: '/import',
      routes: <RouteBase>[
        GoRoute(
          path: '/import',
          builder: (_, __) => Scaffold(
            body: StatementImportPage(
              pick: () async => (
                name: 'statement.csv',
                bytes: Uint8List.fromList(utf8.encode(csv)),
              ),
            ),
          ),
        ),
        GoRoute(
            path: '/transactions',
            builder: (_, __) => const Scaffold(body: Text('transactions'))),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...fallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DsColors.light,
          DsGlass.light,
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('choose a statement, check it, add it; a second time adds none',
      (WidgetTester tester) async {
    final ProviderContainer c = await pump(tester, statement);
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l.importChooseFile));
    await tester.pumpAndSettle();

    expect(find.text(l.importFileRows('statement.csv', 3)), findsOneWidget);
    // The guess is complete: the columns are summed up, folded.
    expect(find.textContaining('${l.fieldDate}: Transaction Date'),
        findsOneWidget);
    expect(find.byType(DropdownButton<int?>), findsNothing);
    await tester.tap(find.text(l.importColumns));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<int?>), findsNWidgets(7));
    expect(find.text(l.importCountAdd(2)), findsOneWidget);
    expect(find.text(l.importCountBad(1)), findsOneWidget);
    expect(find.textContaining('CARREFOUR'), findsOneWidget);

    await tester.tap(find.text(l.importAdd(2)));
    await tester.pumpAndSettle();
    expect(find.text(l.quickAdded(2)), findsOneWidget);
    expect(find.text('transactions'), findsOneWidget);
    final List<Transaction> saved = c.read(transactionsProvider).value!;
    expect(saved.length, 2);
    final Transaction food =
        saved.firstWhere((Transaction t) => t.type == TransactionType.expense);
    expect(food.amount.asDouble, 1240.75);
    expect(food.category, 'الطعام');
    expect(food.description, 'CARREFOUR');
    expect(<int>[food.date.year, food.date.month, food.date.day],
        <int>[2026, 10, 14]);

    // The same file again: everything is already recorded.
    GoRouter.of(tester.element(find.text('transactions'))).go('/import');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.importChooseFile));
    await tester.pumpAndSettle();
    expect(find.text(l.importCountAdd(0)), findsOneWidget);
    expect(find.text(l.importCountKnown(2)), findsOneWidget);
    expect(find.text(l.importNothing), findsOneWidget);
  });

  testWidgets('a file that is not a table says so',
      (WidgetTester tester) async {
    await pump(tester, '\u{D0}\u{CF}\u{11}\u{E0}');
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l.importChooseFile));
    await tester.pumpAndSettle();
    expect(find.text(l.importUnreadable), findsOneWidget);
  });
}
