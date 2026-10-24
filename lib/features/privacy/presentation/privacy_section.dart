import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/stats/app_stats.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/privacy/application/privacy_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Settings → Privacy: the same switch as the eye on KPI cards, plus hiding
/// figures while a transaction is being added, and the anonymous trip count.
class PrivacySection extends ConsumerWidget {
  const PrivacySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final PrivacyState s = ref.watch(privacyProvider);
    final PrivacyController ctrl = ref.read(privacyProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.privacyHint, style: t.bodySmall),
        const SizedBox(height: DsSpacing.sm),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(l.privacyHideAll, style: t.titleSmall),
          value: s.hidden,
          onChanged: ctrl.setHidden,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(l.privacyHideWhileEntering, style: t.titleSmall),
          subtitle: Text(l.privacyHideWhileEnteringHint, style: t.bodySmall),
          value: s.hideWhileEntering,
          onChanged: ctrl.setHideWhileEntering,
        ),
        if (AppEnv.hasSupabase && AppEnv.smartTrip)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l.anonStatsTrips, style: t.titleSmall),
            subtitle: Text(l.anonStatsTripsHint, style: t.bodySmall),
            value: ref.watch(appStatsOnProvider),
            onChanged: ref.read(appStatsOnProvider.notifier).set,
          ),
      ],
    );
  }
}
