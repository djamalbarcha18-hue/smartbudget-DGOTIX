import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/data/checkout_service.dart';
import 'package:smartbudget/features/billing/data/subscription_service.dart';
import 'package:smartbudget/features/billing/domain/user_subscription.dart';
import 'package:smartbudget/features/billing/presentation/plans_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

Widget _host({required bool payTest}) => ProviderScope(
      overrides: <Override>[
        paymentTestModeProvider.overrideWith((_) async => payTest),
        subscriptionProvider.overrideWith((_) async => null as UserSubscription?),
      ],
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
        home: const Scaffold(body: PlansPage()),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('beta: plans are shown with nothing to buy',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    await tester.pumpWidget(_host(payTest: false));
    await tester.pumpAndSettle();
    expect(find.text('Payment test mode'), findsNothing);
    expect(find.textContaining('Upgrade'), findsNothing);
  });

  testWidgets('payment test mode: the banner and the Premium upgrade are offered',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    await tester.pumpWidget(_host(payTest: true));
    await tester.pumpAndSettle();
    expect(find.text('Payment test mode'), findsOneWidget);
    expect(find.textContaining('Upgrade'), findsOneWidget);
    expect(find.text('Premium'), findsWidgets);
    expect(find.text('Basic'), findsNothing);
  });
}
