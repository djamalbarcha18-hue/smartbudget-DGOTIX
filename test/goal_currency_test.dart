import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/goals/application/goals_controller.dart';
import 'package:smartbudget/features/goals/domain/goal.dart';
import 'package:smartbudget/features/goals/presentation/goal_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A goal kept from before a change of the base currency stays in its own
/// currency when edited: its target and saved amount are never reread in
/// the new currency's units.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('editing a yen goal while the base currency is SAR keeps yen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb_base_currency': 'SAR',
    });
    tester.view.physicalSize = const Size(1170, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(goalsProvider, (_, __) {});
    final Goal yen = Goal(
      id: 'g1',
      name: 'Tokyo',
      target: const Money(300000, 'JPY'),
      saved: const Money(50000, 'JPY'),
      createdAt: DateTime(2026),
    );
    await c.read(goalActionsProvider).add(yen);

    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: nav,
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
        home: const Scaffold(body: SizedBox()),
      ),
    ));
    await tester.pumpAndSettle();
    GoalEditorSheet.show(nav.currentContext!, existing: yen);
    await tester.pumpAndSettle();
    expect(find.text('JPY'), findsWidgets);

    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    final Goal saved = c.read(goalsProvider).value!.single;
    expect(saved.target, const Money(300000, 'JPY'));
    expect(saved.saved, const Money(50000, 'JPY'));
  });
}
