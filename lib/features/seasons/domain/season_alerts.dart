import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/seasons/domain/season.dart';

abstract final class SeasonAlerts {
  /// How early a season starts being announced.
  static const int leadDays = 45;

  /// The alert subject for a plan: a preset key ("season:ramadan") or the
  /// custom name. Presentation turns the key into a localized name.
  static String subjectOf(SeasonPlan p) =>
      p.kind == SeasonKind.custom ? p.name : 'season:${p.kind.name}';

  /// Plans starting within [leadDays] that aren't fully funded yet.
  static List<AppAlert> build(List<SeasonPlan> plans, DateTime now) {
    final List<AppAlert> out = <AppAlert>[];
    for (final SeasonPlan p in plans) {
      if (SeasonMath.status(p, now) != SeasonStatus.upcoming) continue;
      final int days = SeasonMath.daysUntil(p, now);
      final Money left = SeasonMath.remainingToSave(p);
      if (days > leadDays || left.minorUnits <= 0) continue;
      out.add(AppAlert(
        kind: AlertKind.seasonApproaching,
        severity: days <= 14 ? AlertSeverity.medium : AlertSeverity.info,
        subject: subjectOf(p),
        amount: left,
        route: '/seasons',
        focusKey: p.id,
        date: p.start,
      ));
    }
    return out;
  }
}
