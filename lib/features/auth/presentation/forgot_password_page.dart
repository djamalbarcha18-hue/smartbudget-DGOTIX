import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/presentation/auth_helpers.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:smartbudget/features/auth/presentation/widgets/password_requirements.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Account recovery in two steps:
///   1. enter the email → a one-time code is emailed;
///   2. enter that code + a new strong password (typed twice).
/// On success the user is signed in (the router then leaves this screen).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const int _resendSeconds = 60;

  final GlobalKey<FormState> _emailForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _resetForm = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      if (_cooldown == 0) t.cancel();
    });
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  /// Step 1 (and "resend"): email a recovery code.
  Future<void> _sendCode() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (!_codeSent && !_emailForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordReset(email: _email.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startCooldown();
      _toast(l.authResetSent);
    } catch (error) {
      if (mounted) _toast(authFailureMessage(error, l));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Step 2: verify the code and set the new password.
  Future<void> _resetPassword() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (!_resetForm.currentState!.validate()) return;
    // Capture before the await: success signs the user in and the router
    // navigates away from this screen.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).resetPasswordWithCode(
            email: _email.text,
            code: _code.text,
            newPassword: _password.text,
          );
      messenger.showSnackBar(SnackBar(content: Text(l.authPasswordUpdated)));
    } catch (error) {
      messenger.showSnackBar(
          SnackBar(content: Text(authFailureMessage(error, l))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeEmail() {
    _timer?.cancel();
    setState(() {
      _codeSent = false;
      _cooldown = 0;
      _code.clear();
      _password.clear();
      _confirm.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return AuthScaffold(
      title: _codeSent ? l.authCodeTitle : l.authForgotTitle,
      subtitle: _codeSent
          ? l.authCodeSubtitle(_email.text.trim())
          : l.authForgotSubtitle,
      children: <Widget>[
        if (!_codeSent) _emailStep(l) else _resetStep(l),
        const SizedBox(height: DsSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(l.authBackToLogin),
          ),
        ),
      ],
    );
  }

  Widget _emailStep(AppLocalizations l) {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DsTextField(
            label: l.authEmail,
            controller: _email,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            validator: (String? v) => AuthValidators.email(v, l),
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: DsSpacing.xl),
          DsButton(
            label: l.authSendReset,
            expand: true,
            onPressed: _loading ? null : _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _resetStep(AppLocalizations l) {
    return Form(
      key: _resetForm,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DsTextField(
              label: l.authCode,
              controller: _code,
              hintText: '••••••',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.oneTimeCode],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (String? v) => AuthValidators.code(v, l),
            ),
            const SizedBox(height: DsSpacing.lg),
            DsTextField(
              label: l.authNewPassword,
              controller: _password,
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.newPassword],
              validator: (String? v) => AuthValidators.newPassword(v, l),
            ),
            PasswordRequirements(controller: _password),
            const SizedBox(height: DsSpacing.lg),
            DsTextField(
              label: l.authConfirmPassword,
              controller: _confirm,
              prefixIcon: Icons.lock_reset_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.newPassword],
              validator: (String? v) =>
                  AuthValidators.confirmPassword(v, _password.text, l),
              onSubmitted: (_) => _resetPassword(),
            ),
            const SizedBox(height: DsSpacing.xl),
            DsButton(
              label: l.authResetPassword,
              expand: true,
              onPressed: _loading ? null : _resetPassword,
            ),
            const SizedBox(height: DsSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  onPressed: (_loading || _cooldown > 0) ? null : _sendCode,
                  child: Text(_cooldown > 0
                      ? l.authResendIn(_cooldown)
                      : l.authResendCode),
                ),
                TextButton(
                  onPressed: _loading ? null : _changeEmail,
                  child: Text(l.authChangeEmail),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
