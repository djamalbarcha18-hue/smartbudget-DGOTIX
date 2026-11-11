import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/application/entitlement_controller.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/feature_gate.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/daret/presentation/daret_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Future<void> _open(WidgetTester tester, Plan plan) async {
  tester.view.physicalSize = const Size(1000, 5000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(ProviderScope(
    overrides: <Override>[effectivePlanProvider.overrideWithValue(plan)],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        DsColors.light,
        DsGlass.light,
      ]),
      home: const Scaffold(
          body: SingleChildScrollView(child: DaretEditorSheet())),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Types [name] in the member field and presses add.
Future<void> _add(WidgetTester tester, String name) async {
  final Finder field = find.widgetWithText(TextField, "Member's name");
  await tester.ensureVisible(field);
  await tester.enterText(field, name);
  await tester.tap(find.byTooltip('Add member'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('the rule: twelve members free, any number on Pro', () {
    expect(
        FeatureGate.evaluate(Feature.daretMembers, plan: Plan.free, used: 11)
            .allowed,
        isTrue);
    final GateDecision full =
        FeatureGate.evaluate(Feature.daretMembers, plan: Plan.free, used: 12);
    expect(full.allowed, isFalse);
    expect(full.reason, GateReason.quotaReached);
    expect(full.suggestedTier, Plan.pro);
    expect(
        FeatureGate.evaluate(Feature.daretMembers, plan: Plan.pro, used: 40)
            .allowed,
        isTrue);
  });

  testWidgets('free: the twelfth member goes in, the thirteenth asks for Pro',
      (WidgetTester tester) async {
    await _open(tester, Plan.free);
    // The sheet starts with "Me" as the first member.
    for (int i = 2; i <= 12; i++) {
      await _add(tester, 'Member $i');
    }
    expect(find.text('Member 12'), findsOneWidget);

    await _add(tester, 'Thirteenth');
    // Not added: the name is still only in the field, and Pro is offered.
    expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, "Member's name"))
            .controller!
            .text,
        'Thirteenth');
    expect(find.textContaining('Pro'), findsWidgets);
  });

  testWidgets('Pro: a thirteenth member and more go in',
      (WidgetTester tester) async {
    await _open(tester, Plan.pro);
    for (final String n in <String>[
      'Sara',
      'Leila',
      'Omar',
      'Youssef',
      'Mariam'
    ]) {
      await _add(tester, n);
    }
    expect(find.text('Youssef'), findsOneWidget);
    expect(find.text('Mariam'), findsOneWidget);
    // The field is empty again: both were taken into the list.
    expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, "Member's name"))
            .controller!
            .text,
        isEmpty);
  });
}
