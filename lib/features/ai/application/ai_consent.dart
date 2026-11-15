import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartbudget/core/storage/account_keys.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Asked once per account, before anything is sent to DGOTIX AI (Google
/// Gemini, through the app's server): what leaves the device and where it
/// goes. Kept on the device as `sb_ai_consent_<account>`.
abstract final class AiConsent {
  static const String base = 'sb_ai_consent';

  static bool given(SharedPreferences prefs, String? account) =>
      prefs.getBool(AccountKeys.of(base, account)) ?? false;

  /// True when the user has agreed (now or before); false when they declined
  /// or the screen went away. Nothing is sent in that case.
  static Future<bool> ensure(BuildContext context, WidgetRef ref) async {
    final String? account = ref.read(currentAccountIdProvider);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (given(prefs, account)) return true;
    if (!context.mounted) return false;
    final AppLocalizations l = AppLocalizations.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        icon: const Icon(Icons.privacy_tip_outlined),
        title: Text(l.aiConsentTitle),
        content: SingleChildScrollView(child: Text(l.aiConsentBody)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('ai-consent-agree'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.aiConsentAgree),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await prefs.setBool(AccountKeys.of(base, account), true);
    return true;
  }
}
