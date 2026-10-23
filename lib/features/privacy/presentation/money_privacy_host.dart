import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/money_privacy.dart';
import 'package:smartbudget/features/privacy/application/privacy_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Hands the privacy mode to every KPI card in the app.
class MoneyPrivacyHost extends ConsumerWidget {
  const MoneyPrivacyHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    return MoneyPrivacy(
      masked: ref.watch(privacyProvider.select((PrivacyState s) => s.masked)),
      onToggle: () => ref.read(privacyProvider.notifier).toggle(),
      hideLabel: l.privacyHide,
      showLabel: l.privacyShow,
      peekHint: l.privacyPeekHint,
      child: child,
    );
  }
}
