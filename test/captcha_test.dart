import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/domain/auth_repository.dart';
import 'package:smartbudget/features/auth/domain/auth_user.dart';
import 'package:smartbudget/features/auth/presentation/captcha/captcha.dart';
import 'package:smartbudget/features/auth/presentation/forgot_password_page.dart';
import 'package:smartbudget/features/auth/presentation/login_page.dart';
import 'package:smartbudget/features/auth/presentation/signup_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Records what reaches the auth backend.
class RecordingAuth implements AuthRepository {
  final List<String> calls = <String>[];
  final StreamController<AuthUser?> _users = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() => _users.stream;
  @override
  AuthUser? get currentUser => null;
  @override
  Future<AuthUser> signIn(
      {required String email, required String password, String? captchaToken}) async {
    calls.add('signIn:$captchaToken');
    return AuthUser(id: 'u', email: email);
  }

  @override
  Future<AuthUser?> signUp(
      {required String email,
      required String password,
      String? displayName,
      String? captchaToken}) async {
    calls.add('signUp:$captchaToken');
    return null;
  }

  @override
  Future<void> sendPasswordReset({required String email, String? captchaToken}) async =>
      calls.add('reset:$captchaToken');
  @override
  Future<void> resetPasswordWithCode(
      {required String email, required String code, required String newPassword}) async {}
  @override
  Future<void> signOut() async {}
  @override
  void dispose() => _users.close();
}

/// A check that is on and answers [token] (null: not passed).
class FakeSolver extends CaptchaSolver {
  const FakeSolver(this.token, {this.on = true});
  final String? token;
  final bool on;
  @override
  bool get enabled => on;
  @override
  Future<String?> solve(BuildContext context) async => token;
}

Future<RecordingAuth> pump(WidgetTester tester, Widget page, CaptchaSolver solver) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  // The test font draws every letter as a wide square, so some rows of the
  // auth card overflow here (not with real fonts): only that is ignored.
  final FlutterExceptionHandler? onError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    onError?.call(d);
  };
  addTearDown(() => FlutterError.onError = onError);
  final RecordingAuth auth = RecordingAuth();
  await tester.pumpWidget(ProviderScope(
    overrides: <Override>[
      authRepositoryProvider.overrideWithValue(auth),
      captchaSolverProvider.overrideWithValue(solver),
    ],
    child: MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        extensions: const <ThemeExtension<dynamic>>[DsColors.dark, DsGlass.dark],
      ),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: page,
    ),
  ));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> fill(WidgetTester tester, List<String> values) async {
  final Finder fields = find.byType(TextFormField);
  for (int i = 0; i < values.length; i++) {
    await tester.enterText(fields.at(i), values[i]);
  }
}

Future<void> submit(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label).hitTestable().first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('sign-in sends the check token', (WidgetTester tester) async {
    final RecordingAuth auth = await pump(tester, const LoginPage(), const FakeSolver('tok-1'));
    await fill(tester, <String>['a@b.co', 'Passw0rd!']);
    await submit(tester, 'Sign in');
    expect(auth.calls, <String>['signIn:tok-1']);
  });

  testWidgets('sign-in stops when the check is not passed', (WidgetTester tester) async {
    final RecordingAuth auth = await pump(tester, const LoginPage(), const FakeSolver(null));
    await fill(tester, <String>['a@b.co', 'Passw0rd!']);
    await submit(tester, 'Sign in');
    expect(auth.calls, isEmpty);
    expect(find.text("Couldn't confirm you're a person. Please try again."), findsOneWidget);
  });

  testWidgets('no check configured: sign-in goes ahead without a token',
      (WidgetTester tester) async {
    final RecordingAuth auth =
        await pump(tester, const LoginPage(), const FakeSolver('unused', on: false));
    await fill(tester, <String>['a@b.co', 'Passw0rd!']);
    await submit(tester, 'Sign in');
    expect(auth.calls, <String>['signIn:null']);
  });

  testWidgets('sign-up sends the check token', (WidgetTester tester) async {
    final RecordingAuth auth = await pump(tester, const SignupPage(), const FakeSolver('tok-2'));
    await fill(tester, <String>['Sam', 'a@b.co', 'Passw0rd!x']);
    await submit(tester, 'Create account');
    expect(auth.calls, <String>['signUp:tok-2']);
  });

  testWidgets('a password reset request sends the check token', (WidgetTester tester) async {
    final RecordingAuth auth =
        await pump(tester, const ForgotPasswordPage(), const FakeSolver('tok-3'));
    await fill(tester, <String>['a@b.co']);
    await submit(tester, 'Send code');
    expect(auth.calls, <String>['reset:tok-3']);
  });
}
