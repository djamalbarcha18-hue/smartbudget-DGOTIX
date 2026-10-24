import 'package:flutter/material.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Logical app sections. Order + grouping is a UX decision (not bound to the
/// legacy 12-sheet layout): the monthly budget is a single screen with a
/// year/month selector rather than 12 separate pages.
enum AppSection {
  dashboard,
  challenges,
  transactions,
  wallets,
  income,
  expenses,
  recurring,
  monthlyBudget,
  goals,
  trips,
  seasons,
  daret,
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

/// Sidebar groups, ordered by how often people need them: every day, then
/// planning and saving, then insight, occasional plans, advanced features,
/// markets, and finally account & help.
enum NavGroup { daily, planning, insights, special, advanced, markets, system }

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

  /// "New" in the menu until the user first opens it (kept for the Islamic
  /// features at launch, then for what each update adds).
  final bool isNew;

  String label(AppLocalizations l) => switch (section) {
        AppSection.dashboard => l.navDashboard,
        AppSection.challenges => l.navChallenges,
        AppSection.transactions => l.navTransactions,
        AppSection.wallets => l.navWallets,
        AppSection.income => l.navIncome,
        AppSection.expenses => l.navExpenses,
        AppSection.recurring => l.navRecurring,
        AppSection.monthlyBudget => l.navMonthlyBudget,
        AppSection.goals => l.navGoals,
        AppSection.trips => l.navTrips,
        AppSection.seasons => l.navSeasons,
        AppSection.daret => l.navDaret,
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
  /// What the menu, search and routes offer: everything, less features not
  /// launched in this build.
  static List<NavDestination> get destinations => <NavDestination>[
        for (final NavDestination d in all)
          if (isLaunched(d) || AppEnv.smartTrip) d,
      ];

  /// In every build (SmartTrip is still in testing).
  static bool isLaunched(NavDestination d) => d.section != AppSection.trips;

  /// Every destination, launched or not.
  static const List<NavDestination> all = <NavDestination>[
    // Every day: see where you stand, record, check the accounts.
    NavDestination(
      section: AppSection.dashboard,
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      group: NavGroup.daily,
    ),
    NavDestination(
      section: AppSection.transactions,
      route: '/transactions',
      icon: Icons.receipt_long_outlined,
      group: NavGroup.daily,
    ),
    NavDestination(
      section: AppSection.expenses,
      route: '/expenses',
      icon: Icons.north_east_outlined,
      group: NavGroup.daily,
    ),
    NavDestination(
      section: AppSection.income,
      route: '/income',
      icon: Icons.south_west_outlined,
      group: NavGroup.daily,
    ),
    NavDestination(
      section: AppSection.wallets,
      route: '/wallets',
      icon: Icons.wallet_outlined,
      group: NavGroup.daily,
    ),
    // Plan & save: the month's budget and what it builds toward.
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
      section: AppSection.challenges,
      route: '/challenges',
      icon: Icons.emoji_events_outlined,
      group: NavGroup.planning,
    ),
    NavDestination(
      section: AppSection.recurring,
      route: '/recurring',
      icon: Icons.event_repeat_outlined,
      group: NavGroup.planning,
    ),
    NavDestination(
      section: AppSection.debts,
      route: '/debts',
      icon: Icons.account_balance_outlined,
      group: NavGroup.planning,
    ),
    // Insights: how it's going.
    NavDestination(
      section: AppSection.reports,
      route: '/reports',
      icon: Icons.insights_outlined,
      group: NavGroup.insights,
    ),
    NavDestination(
      section: AppSection.financialHealth,
      route: '/health',
      icon: Icons.monitor_heart_outlined,
      group: NavGroup.insights,
    ),
    NavDestination(
      section: AppSection.aiAssistant,
      route: '/assistant',
      icon: Icons.auto_awesome_outlined,
      group: NavGroup.insights,
    ),
    // Occasional plans: seasons, daret, projects, zakat.
    NavDestination(
      section: AppSection.seasons,
      route: '/seasons',
      icon: Icons.celebration_outlined,
      group: NavGroup.special,
      isNew: true,
    ),
    NavDestination(
      section: AppSection.daret,
      route: '/daret',
      icon: Icons.groups_2_outlined,
      group: NavGroup.special,
    ),
    NavDestination(
      section: AppSection.portfolio,
      route: '/portfolio',
      icon: Icons.account_balance_wallet_outlined,
      group: NavGroup.special,
    ),
    NavDestination(
      section: AppSection.zakat,
      route: '/zakat',
      icon: Icons.mosque_outlined,
      group: NavGroup.special,
      // Islamic features: shown as new until first opened.
      isNew: true,
    ),
    // Advanced features.
    NavDestination(
      section: AppSection.trips,
      route: '/trips',
      icon: Icons.flight_takeoff_outlined,
      group: NavGroup.advanced,
      isNew: true,
    ),
    // Markets & currencies.
    NavDestination(
      section: AppSection.exchangeRates,
      route: '/exchange-rates',
      icon: Icons.currency_exchange_outlined,
      group: NavGroup.markets,
    ),
    NavDestination(
      section: AppSection.markets,
      route: '/markets',
      icon: Icons.travel_explore_outlined,
      group: NavGroup.markets,
    ),
    // Account & help.
    NavDestination(
      section: AppSection.settings,
      route: '/settings',
      icon: Icons.settings_outlined,
      group: NavGroup.system,
    ),
    NavDestination(
      section: AppSection.guide,
      route: '/guide',
      icon: Icons.explore_outlined,
      group: NavGroup.system,
    ),
    NavDestination(
      section: AppSection.helpSupport,
      route: '/support',
      icon: Icons.help_outline_rounded,
      group: NavGroup.system,
    ),
    NavDestination(
      section: AppSection.plans,
      route: '/plans',
      icon: Icons.workspace_premium_outlined,
      group: NavGroup.system,
    ),
  ];

  static NavGroup groupOf(int index) => destinations[index].group;
}

/// The menu's folding parts, closed until opened (or holding the page open).
enum NavFold { tools, occasions, markets }

/// What the side menu shows, so a newcomer understands it at first sight:
/// a few everyday items, then the rest folded by purpose, then settings and
/// help. Everything stays in search and at its route; income and expenses
/// are filters of the transactions page, the guide is under help, and the
/// plans behind the upgrade card.
abstract final class AppMenu {
  /// Always shown, in this order.
  static const List<AppSection> main = <AppSection>[
    AppSection.dashboard,
    AppSection.transactions,
    AppSection.monthlyBudget,
    AppSection.goals,
    AppSection.reports,
    AppSection.financialHealth,
    AppSection.aiAssistant,
  ];

  static const Map<NavFold, List<AppSection>> folds = <NavFold, List<AppSection>>{
    NavFold.tools: <AppSection>[
      AppSection.wallets,
      AppSection.recurring,
      AppSection.debts,
      AppSection.challenges,
    ],
    NavFold.occasions: <AppSection>[
      AppSection.seasons,
      AppSection.daret,
      AppSection.zakat,
      AppSection.trips,
    ],
    NavFold.markets: <AppSection>[
      AppSection.exchangeRates,
      AppSection.markets,
    ],
  };

  /// Small, at the bottom.
  static const List<AppSection> footer = <AppSection>[
    AppSection.settings,
    AppSection.helpSupport,
  ];

  /// Reached from another menu item: its page lights that item up.
  static const Map<AppSection, AppSection> within = <AppSection, AppSection>{
    AppSection.income: AppSection.transactions,
    AppSection.expenses: AppSection.transactions,
    AppSection.guide: AppSection.helpSupport,
    // The funding plan is a tab of Financial goals.
    AppSection.portfolio: AppSection.goals,
  };

  /// The destination of [s] in this build, or null (not launched).
  static NavDestination? of(AppSection s) => AppNav.destinations
      .where((NavDestination d) => d.section == s)
      .firstOrNull;

  /// The section the menu lights up for [route].
  static AppSection? selectedFor(String route) {
    if (route == '/') return AppSection.dashboard;
    final NavDestination? d = AppNav.destinations
        .where((NavDestination d) => d.route == route)
        .firstOrNull;
    if (d == null) return null;
    return within[d.section] ?? d.section;
  }

  /// The fold holding [section], if any.
  static NavFold? foldOf(AppSection? section) {
    for (final MapEntry<NavFold, List<AppSection>> e in folds.entries) {
      if (e.value.contains(section)) return e.key;
    }
    return null;
  }
}
