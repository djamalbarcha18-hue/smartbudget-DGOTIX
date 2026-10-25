import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/language_names.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/settings/presentation/language_picker.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('every language has a name in every app language', () {
    for (final AppLang ui in AppLang.values) {
      final Set<String> names = <String>{
        for (final AppLang l in AppLang.values) LanguageNames.of(l, inLang: ui),
      };
      expect(names.length, AppLang.values.length, reason: ui.code);
    }
    expect(LanguageNames.of(AppLang.de, inLang: AppLang.ar), 'الألمانية');
    expect(LanguageNames.of(AppLang.ar, inLang: AppLang.en), 'Arabic');
  });

  testWidgets('pick a language from the sheet, then go back from the notice',
      (WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{'sb_locale': 'ar'});
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, _) => MaterialApp(
          locale: ref.watch(localeProvider),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
            DsColors.light,
            DsGlass.light,
          ]),
          builder: (BuildContext context, Widget? child) =>
              LanguageSwitchCurtain(child: child!),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: LanguagePickerField(),
            ),
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(c.read(localeProvider).languageCode, 'ar');

    await t.tap(find.byType(LanguagePickerField));
    await t.pumpAndSettle();
    // Own name first, then the name in the current language.
    expect(find.text('English'), findsOneWidget);
    expect(find.text('الإنجليزية'), findsOneWidget);
    // Eight languages offered: no search field yet.
    expect(
        find.byType(TextField),
        AppLang.offered.length >= LanguagePicker.searchFrom
            ? findsOneWidget
            : findsNothing);

    await t.tap(find.text('English'));
    await t.pumpAndSettle();
    expect(c.read(localeProvider).languageCode, 'en');
    // The way back is written in the language just left.
    expect(find.text('↩ العربية'), findsOneWidget);

    await t.tap(find.text('↩ العربية'));
    await t.pumpAndSettle();
    expect(c.read(localeProvider).languageCode, 'ar');
  });
}
