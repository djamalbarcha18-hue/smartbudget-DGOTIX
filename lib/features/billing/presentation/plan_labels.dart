import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Localized display name for a [Plan]. Kept in the presentation layer so the
/// domain stays free of l10n.
String planName(AppLocalizations l, Plan plan) => switch (plan) {
      Plan.free => l.planFree,
      Plan.basic => l.planBasic,
      Plan.pro => l.planPro,
    };
