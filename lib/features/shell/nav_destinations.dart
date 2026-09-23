import 'package:flutter/material.dart';

import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Logical app sections. Order + grouping is a UX decision (not bound to the
/// legacy 12-sheet layout): the monthly budget is a single screen with a
/// year/month selector rather than 12 separate pages.
enum AppSection {
  dashboard,
  transactions,
  income,
  expenses,
  monthlyBudget,
  goals,
  portfolio,
  debts,
  financialHealth,
  reports,
  zakat,
  exchangeRates,
  markets,
  aiAssistant,
  plans,
  guide,
  settings,
  helpSupport,
}

/// Sidebar groups for a calm, scannable information architecture.
enum NavGroup { overview, money, planning, intelligence, system }

/// Immutable descriptor for a navigation destination.
class NavDestination {
  const NavDestination({
    required this.section,
    required this.route,
    required this.icon,
    required this.group,
    this.isNew = false,
  });

  final AppSection section;
  final String route;
  final IconData icon;
  final NavGroup group;
  final bool isNew;

  String label(AppLocalizations l) => switch (section) {
        AppSection.dashboard => l.navDashboard,
        AppSection.transactions => l.navTransactions,
        AppSection.income => l.navIncome,
        AppSection.expenses => l.navExpenses,
        AppSection.monthlyBudget => l.navMonthlyBudget,
        AppSection.goals => l.navGoals,
        AppSection.portfolio => l.navPortfolio,
        AppSection.debts => l.navDebts,
        AppSection.financialHealth => l.navFinancialHealth,
        AppSection.reports => l.navReports,
        AppSection.zakat => l.navZakat,
        AppSection.exchangeRates => l.navExchangeRates,
        AppSection.markets => l.navMarkets,
        AppSection.aiAssistant => l.navAiAssistant,
        AppSection.plans => l.plansTitle,
        AppSection.guide => l.guideTitle,
        AppSection.settings => l.navSettings,
        AppSection.helpSupport => l.navHelpSupport,
      };
}

/// The canonical navigation list (outline icons; no emoji).
abstract final class AppNav {
  static const List<NavDestination> destinations = <NavDestination>[
    NavDestination(
      section: AppSection.dashboard,
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      group: NavGroup.overview,
    ),
    NavDestination(
      section: AppSection.transactions,
      route: '/transactions',
      icon: Icons.receipt_long_outlined,
      group: NavGroup.money,
    ),
    NavDestination(
      section: AppSection.income,
      route: '/income',
      icon: Icons.south_west_outlined,
      group: NavGroup.money,
    ),
    NavDestination(
      section: AppSection.expenses,
      route: '/expenses',
      icon: Icons.north_east_outlined,
      group: NavGroup.money,
    ),
    NavDestination(
      section: AppSection.monthlyBudget,
      route: '/budget',
      icon: Icons.calendar_month_outlined,
      group: NavGroup.planning,
    ),
    NavDestination(
      section: AppSection.goals,
      route: '/goals',
      icon: Icons.flag_outlined,
      group: NavGroup.planning,
    ),
    NavDestination(
      section: AppSection.portfolio,
      route: '/portfolio',
      icon: Icons.account_balance_wallet_outlined,
      group: NavGroup.planning,
      isNew: true,
    ),
    NavDestination(
      section: AppSection.debts,
      route: '/debts',
      icon: Icons.account_balance_outlined,
      group: NavGroup.planning,
    ),
    NavDestination(
      section: AppSection.financialHealth,
      route: '/health',
      icon: Icons.monitor_heart_outlined,
      group: NavGroup.intelligence,
    ),
    NavDestination(
      section: AppSection.reports,
      route: '/reports',
      icon: Icons.insights_outlined,
      group: NavGroup.intelligence,
    ),
    NavDestination(
      section: AppSection.zakat,
      route: '/zakat',
      icon: Icons.mosque_outlined,
      group: NavGroup.intelligence,
      isNew: true,
    ),
    NavDestination(
      section: AppSection.exchangeRates,
      route: '/exchange-rates',
      icon: Icons.currency_exchange_outlined,
      group: NavGroup.intelligence,
    ),
    NavDestination(
      section: AppSection.markets,
      route: '/markets',
      icon: Icons.travel_explore_outlined,
      group: NavGroup.intelligence,
      isNew: true,
    ),
    NavDestination(
      section: AppSection.aiAssistant,
      route: '/assistant',
      icon: Icons.auto_awesome_outlined,
      group: NavGroup.intelligence,
    ),
    NavDestination(
      section: AppSection.plans,
      route: '/plans',
      icon: Icons.workspace_premium_outlined,
      group: NavGroup.system,
      isNew: true,
    ),
    NavDestination(
      section: AppSection.guide,
      route: '/guide',
      icon: Icons.explore_outlined,
      group: NavGroup.system,
      isNew: true,
    ),
    NavDestination(
      section: AppSection.settings,
      route: '/settings',
      icon: Icons.settings_outlined,
      group: NavGroup.system,
    ),
    NavDestination(
      section: AppSection.helpSupport,
      route: '/support',
      icon: Icons.help_outline_rounded,
      group: NavGroup.system,
    ),
  ];

  static NavGroup groupOf(int index) => destinations[index].group;
}
