import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/auth/domain/auth_failure.dart';
import 'package:smartbudget/features/auth/presentation/captcha/turnstile_view.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Proves a person is signing in, signing up or asking for a password reset,
/// so scripts can't make accounts in bulk: a Cloudflare Turnstile check whose
/// token goes with the request, and Supabase Auth verifies it (once CAPTCHA
/// protection is on in Authentication > Attack Protection). Off while
/// [AppEnv.turnstileSiteKey] is empty.
class CaptchaSolver {
  const CaptchaSolver();

  bool get enabled => AppEnv.turnstileSiteKey.isNotEmpty;

  /// The check's token, or null when it failed or was cancelled.
  Future<String?> solve(BuildContext context) => TurnstileDialog.show(context);
}

final captchaSolverProvider =
    Provider<CaptchaSolver>((_) => const CaptchaSolver());

/// The token for the next sign-in, sign-up or reset request: null when no
/// check is configured. Throws [AuthFailureKind.captchaFailed] when the check
/// isn't passed.
Future<String?> captchaToken(BuildContext context, WidgetRef ref) async {
  final CaptchaSolver solver = ref.read(captchaSolverProvider);
  if (!solver.enabled) return null;
  final String? token = await solver.solve(context);
  if (token == null || token.isEmpty) {
    throw const AuthFailure(AuthFailureKind.captchaFailed);
  }
  return token;
}

/// A small dialog holding the Turnstile check; it closes on its own once the
/// check is passed (usually without a click).
class TurnstileDialog extends StatefulWidget {
  const TurnstileDialog({super.key});

  static Future<String?> show(BuildContext context) => showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const TurnstileDialog(),
      );

  @override
  State<TurnstileDialog> createState() => _TurnstileDialogState();
}

class _TurnstileDialogState extends State<TurnstileDialog> {
  bool _closed = false;

  void _close(String? token) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(token);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.captchaTitle),
      content: SizedBox(
        width: 320,
        height: 80,
        child: TurnstileView(
          query: <String, String>{
            'sitekey': AppEnv.turnstileSiteKey,
            'theme': Theme.of(context).brightness == Brightness.dark
                ? 'dark'
                : 'light',
            'lang': Localizations.localeOf(context).languageCode,
          },
          onResult: _close,
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => _close(null), child: Text(l.cancel)),
      ],
    );
  }
}
