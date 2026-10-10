import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/features/reports/application/reports_controller.dart';
import 'package:smartbudget/features/reports/domain/report_period.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A page with one button that asks [PlanLimits] whether a third goal may be
/// added (two exist), and remembers the answer.
class _Probe extends StatelessWidget {
  const _Probe(this.result);
  final List<bool> result;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          onPressed: () =>
              result.add(PlanLimits.allowAdd(context, Feature.goals, (_) => 2)),
          child: const Text('add'),
        ),
      );
}

Widget _host(Plan plan, Widget child) => ProviderScope(
      overrides: <Override>[effectivePlanProvider.overrideWithValue(plan)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            DsColors.light,
            DsGlass.light
          ],
        ),
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('FREE at its limit sees the upgrade sheet, nothing is added',
      (WidgetTester tester) async {
    final List<bool> result = <bool>[];
    await tester.pumpWidget(_host(Plan.free, _Probe(result)));
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    expect(result, <bool>[false]);
    expect(find.text("You've reached the free plan's limit"), findsOneWidget);
    expect(find.text('See plans'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('See plans'), findsNothing);
  });

  testWidgets('Plus adds without a prompt', (WidgetTester tester) async {
    final List<bool> result = <bool>[];
    await tester.pumpWidget(_host(Plan.basic, _Probe(result)));
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    expect(result, <bool>[true]);
    expect(find.text('See plans'), findsNothing);
  });

  testWidgets('a locked section shows the plan that includes it',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
        Plan.free, const LockedFeatureCard(feature: Feature.healthDetails)));
    expect(find.text('Financial health details and tips is included in Plus.'),
        findsOneWidget);
  });

  group('reports without full access', () {
    ProviderContainer container(Plan plan) => ProviderContainer(
        overrides: <Override>[effectivePlanProvider.overrideWithValue(plan)]);

    test('FREE is shown a month, never a year or a quarter', () {
      final ProviderContainer c = container(Plan.free);
      addTearDown(c.dispose);
      c.read(selectedReportPeriodProvider.notifier).state = ReportPeriod.yearly;
      expect(c.read(effectiveReportPeriodProvider), ReportPeriod.monthly);
      expect(c.read(effectiveReportSubProvider), AppClock.now().month);
    });

    test('FREE can open the previous month but not an older one', () {
      final ProviderContainer c = container(Plan.free);
      addTearDown(c.dispose);
      final DateTime now = AppClock.now();
      c.read(selectedReportPeriodProvider.notifier).state =
          ReportPeriod.monthly;
      for (int m = 1; m <= 12; m++) {
        c.read(selectedReportSubProvider.notifier).state = m;
        final bool open = freeReportMonths(now).contains(m);
        expect(c.read(effectiveReportSubProvider), open ? m : now.month,
            reason: 'month $m');
      }
    });

    test('Plus sees what was chosen', () {
      final ProviderContainer c = container(Plan.basic);
      addTearDown(c.dispose);
      c.read(selectedReportPeriodProvider.notifier).state =
          ReportPeriod.quarterly;
      c.read(selectedReportSubProvider.notifier).state = 2;
      expect(c.read(effectiveReportPeriodProvider), ReportPeriod.quarterly);
      expect(c.read(effectiveReportSubProvider), 2);
    });

    test('the free months are this one and the one before, same year', () {
      expect(freeReportMonths(DateTime(2026, 10, 10)), <int>[9, 10]);
      expect(freeReportMonths(DateTime(2026, 1, 5)), <int>[1]);
    });
  });
}
