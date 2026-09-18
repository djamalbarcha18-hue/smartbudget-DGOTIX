import 'package:smartbudget/features/portfolio/domain/project.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Localized name for a project horizon.
String horizonLabel(ProjectHorizon h, AppLocalizations l) => switch (h) {
      ProjectHorizon.near => l.horizonNear,
      ProjectHorizon.mid => l.horizonMid,
      ProjectHorizon.long => l.horizonLong,
    };

/// One-line description of the horizon's timeframe.
String horizonSubtitle(ProjectHorizon h, AppLocalizations l) => switch (h) {
      ProjectHorizon.near => l.horizonNearHint,
      ProjectHorizon.mid => l.horizonMidHint,
      ProjectHorizon.long => l.horizonLongHint,
    };
