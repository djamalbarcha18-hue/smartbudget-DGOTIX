import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Localized display name for a [Plan]. Kept in the presentation layer so the
/// domain stays free of l10n.
String planName(AppLocalizations l, Plan plan) => switch (plan) {
      Plan.free => l.planFree,
      Plan.pro => l.planPro,
    };

/// The label of a button that leads to the plans: "Upgrade now", or in the
/// store app (which does not sell) just "Pro features", opening a plain note.
String upgradeLabel(AppLocalizations l, {bool ai = false}) => AppEnv
        .storeFreeMode
    ? l.storePlanTitle
    : (ai ? l.aiUpgrade : l.upgradeCta);
