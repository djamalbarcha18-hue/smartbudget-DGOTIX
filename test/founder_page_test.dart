// The founder page: built, but hidden in every build until it is launched
// with --dart-define=FOUNDER_PAGE=true.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/about/presentation/founder_page.dart';
import 'package:smartbudget/features/support/presentation/support_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        DsColors.light,
        DsGlass.light,
      ]),
      home: Scaffold(body: home),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('what the page says is exactly what the founder made public', () {
    expect(AppConfig.founderName, 'Boulahdid Djamal Eddine');
    expect(AppConfig.founderRole, 'Founder of DGOTIX');
    expect(AppConfig.founderFocus, 'Digital Product Development & Innovation');
    expect(AppConfig.founderBackground,
        <String>['Mechanical Engineering', 'Industrial Production']);
    expect(AppConfig.founderEmail, 'contactdgotix@gmail.com');
  });

  test('no software or computer engineering title anywhere', () {
    final String all = <String>[
      AppConfig.founderRole,
      AppConfig.founderFocus,
      ...AppConfig.founderBackground,
    ].join(' ').toLowerCase();
    expect(all, isNot(contains('software engineer')));
    expect(all, isNot(contains('computer engineer')));
    expect(all, isNot(contains('developer')));
  });

  test('initials for the avatar', () {
    expect(FounderPage.initialsOf('Boulahdid Djamal Eddine'), 'BD');
    expect(FounderPage.initialsOf('  Djamal '), 'D');
    expect(FounderPage.initialsOf(''), '');
  });

  testWidgets('the page shows the role first and the background below',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const FounderPage()));
    await tester.pump();

    expect(find.text('Founder'), findsOneWidget);
    expect(find.text('Boulahdid Djamal Eddine'), findsOneWidget);
    expect(find.text('BD'), findsOneWidget);
    expect(find.text('Founder of DGOTIX'), findsOneWidget);
    expect(find.text('Digital Product Development & Innovation'),
        findsOneWidget);
    expect(find.text('Professional Background'), findsOneWidget);
    expect(find.text('Mechanical Engineering'), findsOneWidget);
    expect(find.text('Industrial Production'), findsOneWidget);
    expect(find.text('contactdgotix@gmail.com'), findsOneWidget);

    final double role = tester.getTopLeft(find.text('Founder of DGOTIX')).dy;
    final double background =
        tester.getTopLeft(find.text('Professional Background')).dy;
    expect(role, lessThan(background));
  });

  testWidgets('the professional lines stay in English in Arabic',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const FounderPage(), locale: const Locale('ar')));
    await tester.pump();

    expect(find.text('المؤسس'), findsOneWidget);
    expect(find.text('Founder of DGOTIX'), findsOneWidget);
    expect(find.text('Professional Background'), findsOneWidget);
  });

  testWidgets('hidden: Help & Support has no link to it',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const SupportPage()));
    await tester.pump();

    expect(AppEnv.founderPage, isFalse);
    expect(find.text('Founder'), findsNothing);
    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
  }, skip: AppEnv.founderPage);
}
