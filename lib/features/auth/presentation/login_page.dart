import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/design_system/brand/dgotix_owl.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/data/device_data_adoption.dart';
import 'package:smartbudget/features/auth/domain/auth_failure.dart';
import 'package:smartbudget/features/auth/presentation/auth_helpers.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:smartbudget/features/auth/presentation/captcha/captcha.dart';
import 'package:smartbudget/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  // The owl beside the title: it reads along while the user types, dances
  // while signing in, and frowns at a wrong password (or tilts its head,
  // puzzled, at any other failure) until the user tries again.
  bool _typing = false;
  OwlMood? _upset;
  Timer? _upsetTimer;

  @override
  void initState() {
    super.initState();
    _password.addListener(_calmDown);
  }

  /// Editing the password again calms the owl (cursor moves don't). Only
  /// the length is kept, never a copy of the password.
  int _lastLength = 0;
  void _calmDown() {
    final int length = _password.text.length;
    if (length == _lastLength) return;
    _lastLength = length;
    if (_upset != null) setState(() => _upset = null);
  }

  void _upsetFor(OwlMood mood) {
    _upsetTimer?.cancel();
    setState(() => _upset = mood);
    _upsetTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _upset = null);
    });
  }

  OwlMood get _owlMood {
    if (_loading) return OwlMood.dancing;
    if (_upset != null) return _upset!;
    if (_typing) return OwlMood.reading;
    return OwlMood.idle;
  }

  @override
  void dispose() {
    _upsetTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    _upsetTimer?.cancel();
    setState(() {
      _loading = true;
      _upset = null;
    });
    try {
      final String? captcha = await captchaToken(context, ref);
      await ref.read(authControllerProvider.notifier).signIn(
            email: _email.text,
            password: _password.text,
            captchaToken: captcha,
          );
      // Navigation is handled by the router's auth guard.
    } catch (error) {
      final bool wrongLogin = error is AuthFailure &&
          error.kind == AuthFailureKind.invalidCredentials;
      // Accounts made before real sign-in lived on the device only: their
      // owners must create the real account once (their data follows).
      final bool deviceOnly = wrongLogin &&
          AppEnv.hasSupabase &&
          hasDeviceOnlyData(await SharedPreferences.getInstance(), _email.text);
      if (!mounted) return;
      _upsetFor(wrongLogin ? OwlMood.angry : OwlMood.confused);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: Duration(seconds: wrongLogin ? 10 : 4),
        content: Text(deviceOnly
            ? l.authDeviceAccountHint
            : authFailureMessage(error, l)),
        action: wrongLogin
            ? SnackBarAction(
                label: l.authCreateAccountAction,
                onPressed: () => context.go('/signup'),
              )
            : null,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    return AuthScaffold(
      title: l.authSignInTitle,
      subtitle: l.authSignInSubtitle,
      mascot: DgotixOwl(size: 84, interactive: true, mood: _owlMood),
      children: <Widget>[
        Form(
          key: _formKey,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (bool f) => setState(() => _typing = f),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DsTextField(
                  label: l.authEmail,
                  controller: _email,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: (String? v) => AuthValidators.email(v, l),
                ),
                const SizedBox(height: DsSpacing.lg),
                DsTextField(
                  label: l.authPassword,
                  controller: _password,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  validator: (String? v) => AuthValidators.password(v, l),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: DsSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => context.go('/forgot'),
                    child: Text(l.authForgotPassword),
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                DsButton(
                  label: l.authSignIn,
                  expand: true,
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
        const GoogleSignInSection(),
        const SizedBox(height: DsSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(l.authNoAccount, style: Theme.of(context).textTheme.bodySmall),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: Text(l.authCreateOne, style: TextStyle(color: c.brand)),
            ),
          ],
        ),
      ],
    );
  }
}
