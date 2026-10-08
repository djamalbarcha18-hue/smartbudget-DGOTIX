import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/exchange_rates/presentation/exchange_rates_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Fixed rates, no network.
class _FixedRates extends RatesController {
  @override
  Map<String, double> build() =>
      <String, double>{'USD': 1.0, 'SAR': 3.75, 'EUR': 0.92, 'AED': 3.6725};
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('the converter updates while the amount is typed',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[ratesProvider.overrideWith(_FixedRates.new)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
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
        home: const Scaffold(body: ExchangeRatesPage()),
      ),
    ));
    await tester.pump();
    // 100 USD -> SAR by default.
    expect(find.textContaining('375.00'), findsWidgets);

    // Typing alone (no submit) refreshes the result.
    await tester.enterText(find.byType(TextField).first, '3000');
    await tester.pump();
    expect(find.textContaining('11,250.00'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
