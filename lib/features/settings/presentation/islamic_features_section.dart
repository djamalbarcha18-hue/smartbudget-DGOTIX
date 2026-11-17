import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smartbudget/core/settings/islamic_features.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Settings: "Show Islamic features" (zakat, sadaqah, Ramadan and Eid).
/// The switch moves at once; the screens follow without a restart.
class IslamicFeaturesSection extends StatelessWidget {
  const IslamicFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return ValueListenableBuilder<bool>(
      valueListenable: IslamicFeatures.enabled,
      builder: (BuildContext context, bool on, Widget? _) =>
          SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: on,
        onChanged: (bool v) {
          HapticFeedback.selectionClick();
          IslamicFeatures.set(v);
        },
        title: Text(l.islamicFeaturesTitle, style: t.titleSmall),
        subtitle: Text(l.islamicFeaturesHint,
            style: t.bodySmall?.copyWith(color: c.textMuted)),
      ),
    );
  }
}
