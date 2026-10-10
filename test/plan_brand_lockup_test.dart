import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/design_system/brand/dgotix_brand_lockup.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/billing/presentation/plan_brand_lockup.dart';

Widget host(Widget child, {Plan? plan, Brightness brightness = Brightness.light}) =>
    ProviderScope(
      overrides: <Override>[
        if (plan != null) effectivePlanProvider.overrideWithValue(plan),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: brightness,
          extensions: brightness == Brightness.dark
              ? const <ThemeExtension<dynamic>>[DsColors.dark, DsGlass.dark]
              : const <ThemeExtension<dynamic>>[DsColors.light, DsGlass.light],
        ),
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final (Plan plan, String label) in <(Plan, String)>[
    (Plan.free, 'FREE'),
    (Plan.basic, 'PLUS'),
    (Plan.pro, 'PRO'),
  ]) {
    testWidgets('a $label user sees the $label badge', (WidgetTester tester) async {
      await tester.pumpWidget(host(const PlanBrandLockup(logoHeight: 56), plan: plan));
      expect(find.text(label), findsOneWidget);
      expect(find.text('Digital Productivity Solutions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('each plan stands out a little more than the one before', () {
    expect(PlanBrandLockup.styleFor(Plan.free), LockupBadgeStyle.subtle);
    expect(PlanBrandLockup.styleFor(Plan.basic), LockupBadgeStyle.accent);
    expect(PlanBrandLockup.styleFor(Plan.pro), LockupBadgeStyle.solid);
  });

  testWidgets('signed out (no plan known): no badge', (WidgetTester tester) async {
    await tester.pumpWidget(host(const DgotixBrandLockup(logoHeight: 56)));
    for (final String label in <String>['FREE', 'PLUS', 'PRO']) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('dark mode renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(host(const PlanBrandLockup(logoHeight: 56),
        plan: Plan.basic, brightness: Brightness.dark));
    expect(find.text('PLUS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
