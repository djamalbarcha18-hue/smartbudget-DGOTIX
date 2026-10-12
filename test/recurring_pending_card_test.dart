import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/recurring/application/recurring_controller.dart';
import 'package:smartbudget/features/recurring/domain/recurrence_engine.dart';
import 'package:smartbudget/features/recurring/domain/recurring_rule.dart';
import 'package:smartbudget/features/recurring/presentation/recurring_page.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final RecurringRule bonus = RecurringRule(
    id: 'rule-bonus',
    type: TransactionType.income,
    category: 'مكافآت وحوافز',
    amount: const Money(3000000, 'USD'),
    description: 'Performance bonus',
    frequency: RecurrenceFrequency.quarterly,
    startDate: DateTime(2026, 1, 15),
    lastPosted: DateTime(2026, 1, 15),
    variableAmount: true,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget host(Locale locale) => ProviderScope(
        overrides: <Override>[
          recurringRulesProvider.overrideWith(
              (_) => Stream<List<RecurringRule>>.value(<RecurringRule>[bonus])),
          pendingRecurringProvider.overrideWithValue(<PendingOccurrence>[
            PendingOccurrence(
                rule: bonus, date: DateTime(2026, 4, 15), more: 1),
          ]),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
            DsColors.light,
            DsGlass.light
          ]),
          home: const Scaffold(body: RecurringPage()),
        ),
      );

  for (final Locale locale in const <Locale>[Locale('en'), Locale('ar')]) {
    testWidgets('a bonus waiting for its amount (${locale.languageCode})',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(locale));
      await tester.pumpAndSettle();
      final AppLocalizations l = await AppLocalizations.delegate.load(locale);
      expect(find.text(l.recurringAwaitTitle), findsOneWidget);
      expect(find.text(l.recurringVariableBadge), findsOneWidget);
      expect(find.text(l.recurringSkip), findsOneWidget);
      // The fixed totals leave the bonus out; it shows as expected income.
      expect(find.textContaining('≈'), findsWidgets);

      await tester.tap(find.text(l.recurringConfirm));
      await tester.pumpAndSettle();
      expect(find.text(l.recurringConfirmTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
