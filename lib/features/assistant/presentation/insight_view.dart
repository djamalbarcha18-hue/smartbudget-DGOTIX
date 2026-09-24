import 'package:flutter/material.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/assistant/domain/insight_engine.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The presentation view of an [Insight]: its icon, tone colour and the
/// localized sentence. Shared by the Assistant page and the dashboard card so
/// the phrasing lives in ONE place (money/percent formatted here, never in the
/// domain engine).
class InsightView {
  const InsightView({
    required this.icon,
    required this.color,
    required this.message,
  });
  final IconData icon;
  final Color color;
  final String message;
}

InsightView describeInsight(BuildContext context, Insight i) {
  final DsColors c = context.dsColors;
  final AppLocalizations l = AppLocalizations.of(context);
  final bool ar = Localizations.localeOf(context).languageCode == 'ar';

  final Color color = switch (i.tone) {
    InsightTone.positive => c.income,
    InsightTone.warning => c.warning,
    InsightTone.info => c.brand,
  };
  final IconData icon = switch (i.tone) {
    InsightTone.positive => Icons.check_circle_outline_rounded,
    InsightTone.warning => Icons.warning_amber_rounded,
    InsightTone.info => Icons.lightbulb_outline_rounded,
  };

  // Figures are wrapped in a left-to-right isolate so a trailing "%" or "$"
  // stays with its number inside an Arabic sentence (not "٪45.0." flipped).
  String iso(String s) => '\u2066$s\u2069';
  String money(int? minor) =>
      iso(MoneyFormatter.format(Money(minor ?? 0, i.currency ?? 'USD')));

  final String message = switch (i.key) {
    InsightKey.netDeficit => l.insightNetDeficit(money(i.amountMinor)),
    InsightKey.netSurplus => l.insightNetSurplus(money(i.amountMinor)),
    InsightKey.savingsRate =>
      l.insightSavingsRate(iso(MoneyFormatter.percent(i.rate ?? 0))),
    InsightKey.topExpenseCategory => l.insightTopExpense(
        Catalog.label(i.category ?? '', ar: ar), money(i.amountMinor)),
    InsightKey.healthExcellent => l.insightHealthExcellent,
    InsightKey.healthVeryGood => l.insightHealthVeryGood,
    InsightKey.healthGood => l.insightHealthGood,
    InsightKey.healthFair => l.insightHealthFair,
    InsightKey.healthNeedsWork => l.insightHealthNeedsWork,
    InsightKey.goalsAchieved => l.insightGoalsAchieved(i.count ?? 0),
    InsightKey.goalsUrgent => l.insightGoalsUrgent(i.count ?? 0),
    InsightKey.debtsOverdue => l.insightDebtsOverdue(i.count ?? 0),
    InsightKey.debtsOwedToMe => l.insightDebtsOwedToMe(money(i.amountMinor)),
    InsightKey.debtsOwedByMe => l.insightDebtsOwedByMe(money(i.amountMinor)),
    InsightKey.zakatDue => l.insightZakatDue(money(i.amountMinor)),
  };

  return InsightView(icon: icon, color: color, message: message);
}
