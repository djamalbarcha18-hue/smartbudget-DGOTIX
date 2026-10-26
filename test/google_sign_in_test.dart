import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/localization/fallback_localizations.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/data/fake_auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_repository.dart';
import 'package:smartbudget/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pump(WidgetTester tester, {required bool on}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer c = ProviderContainer(overrides: <Override>[
      googleSignInEnabledProvider.overrideWithValue(on),
      authRepositoryProvider.overrideWith((Ref ref) {
        final AuthRepository repo = FakeAuthRepository();
        ref.onDispose(repo.dispose);
        return repo;
      }),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
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
        home: const Scaffold(body: GoogleSignInSection()),
      ),
    ));
    await tester.pumpAndSettle();
    return c;
  }

  test('off in every build unless asked for', () {
    expect(AppEnv.googleSignIn, isFalse);
  });

  testWidgets('hidden: nothing on the page', (WidgetTester tester) async {
    await pump(tester, on: false);
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.authContinueGoogle), findsNothing);
    expect(find.text(l.authOr), findsNothing);
  });

  testWidgets('on: a tap signs in (the sample account in development)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pump(tester, on: true);
    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.authOr), findsOneWidget);
    await tester.tap(find.text(l.authContinueGoogle));
    await tester.pumpAndSettle();
    expect(c.read(authRepositoryProvider).currentUser?.email,
        'google.user@example.com');
  });
}
