import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/ds_text_field.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/presentation/auth_helpers.dart';
import 'package:smartbudget/features/auth/presentation/widgets/auth_scaffold.dart';
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: _email.text,
            password: _password.text,
          );
      // Navigation is handled by the router's auth guard.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authFailureMessage(error, l))),
      );
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
      children: <Widget>[
        Form(
          key: _formKey,
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
