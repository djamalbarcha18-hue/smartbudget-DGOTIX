import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/analytics/domain/alerts.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The display-ready form of an [AppAlert] (localized + formatted). Shared by
/// the dashboard alerts section and the top-bar notifications bell so the
/// mapping lives in one place.
class AlertView {
  const AlertView({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.route,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final String route;
}

/// Maps an [AppAlert] to localized text, a severity color and an icon.
AlertView describeAlert(BuildContext context, AppAlert a) {
  final DsColors c = context.dsColors;
  final AppLocalizations l = AppLocalizations.of(context);
  final bool ar = Localizations.localeOf(context).languageCode == 'ar';

  final (Color color, IconData icon) = switch (a.severity) {
    AlertSeverity.high => (c.expense, Icons.error_outline_rounded),
    AlertSeverity.medium => (c.warning, Icons.warning_amber_rounded),
    AlertSeverity.info => (c.brand, Icons.info_outline_rounded),
    AlertSeverity.success => (c.income, Icons.check_circle_outline_rounded),
  };

  final String subject =
      a.subject.isEmpty ? '' : Catalog.label(a.subject, ar: ar);
  final String amount = MoneyFormatter.format(a.amount);
  final DateTime now = DateTime.now();
  final DateTime? when = a.date;
  final bool tomorrow = when != null &&
      DateTime(when.year, when.month, when.day) ==
          DateTime(now.year, now.month, now.day + 1);
  final String date = when == null ? '' : DateFormat('yyyy-MM-dd').format(when);

  final String title = switch (a.kind) {
    AlertKind.budgetOver => l.alertTitleBudgetOver,
    AlertKind.budgetNear => l.alertTitleBudgetNear,
    AlertKind.netNegative => l.alertTitleNetNegative,
    AlertKind.savingsLow => l.alertTitleSavingsLow,
    AlertKind.goalOverdue => l.alertTitleGoalOverdue,
    AlertKind.goalUrgent => l.alertTitleGoalUrgent,
    AlertKind.recurringUpcoming => l.alertTitleRecurringUpcoming,
    AlertKind.backupDue => l.alertTitleBackupDue,
  };
  final String description = switch (a.kind) {
    AlertKind.budgetOver => l.alertBudgetOver(subject, amount),
    AlertKind.budgetNear => l.alertBudgetNear(subject, amount),
    AlertKind.netNegative => l.alertNetNegative(amount),
    AlertKind.savingsLow => l.alertSavingsLow,
    AlertKind.goalOverdue => l.alertGoalOverdue(subject, amount),
    AlertKind.goalUrgent => l.alertGoalUrgent(subject, amount),
    AlertKind.recurringUpcoming => tomorrow
        ? l.alertRecurringTomorrow(subject, amount)
        : l.alertRecurringUpcoming(subject, amount, date),
    AlertKind.backupDue => l.alertBackupDue,
  };
  final String action = switch (a.route) {
    '/budget' => l.actionViewBudget,
    '/goals' => l.actionViewGoals,
    '/health' => l.actionViewHealth,
    '/recurring' => l.actionViewRecurring,
    '/settings' => l.actionOpenSettings,
    _ => l.actionViewReport,
  };

  return AlertView(
    color: color,
    icon: icon,
    title: title,
    description: description,
    actionLabel: action,
    route: a.route,
  );
}
