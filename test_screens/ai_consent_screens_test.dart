// ignore_for_file: invalid_use_of_visible_for_testing_member
// Screenshot of the DGOTIX AI consent dialog, for review before "publish".
// Not part of the normal test run (see screenshots.yml).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/latin_digits.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/ai/application/ai_consent.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Future<void> _loadFonts() async {
  final List<dynamic> manifest = json.decode(
      await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final dynamic f in manifest) {
    final FontLoader loader = FontLoader(f['family'] as String);
    for (final dynamic a in f['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load(a['asset'] as String));
    }
    await loader.load();
  }
}

ThemeData _theme(Locale locale) {
  final ThemeData t = DsTheme.dark(
      lang: locale.languageCode == 'ar' ? AppLang.ar : AppLang.fr);
  return t.copyWith(
    textTheme: t.textTheme
        .apply(fontFamily: 'SbTajawal', fontFamilyFallback: <String>['SbInter']),
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    LatinDigits.enforce();
    await _loadFonts();
  });

  for (final Locale locale in const <Locale>[Locale('ar'), Locale('fr')]) {
    final String lang = locale.languageCode;
    testWidgets('ai consent ($lang)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          currentAccountIdProvider.overrideWithValue('preview'),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: _theme(locale),
          home: Consumer(
            builder: (BuildContext context, WidgetRef ref, _) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('open'),
                  onPressed: () => AiConsent.ensure(context, ref),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('open')));
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai-consent-agree')), findsOneWidget);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/ai_consent_$lang.png'));
    });
  }
}
