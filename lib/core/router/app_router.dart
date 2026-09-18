import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/presentation/forgot_password_page.dart';
import 'package:smartbudget/features/auth/presentation/login_page.dart';
import 'package:smartbudget/features/auth/presentation/signup_page.dart';
import 'package:smartbudget/features/dashboard/presentation/dashboard_page.dart';
import 'package:smartbudget/features/debts/presentation/debts_page.dart';
import 'package:smartbudget/features/exchange_rates/presentation/exchange_rates_page.dart';
import 'package:smartbudget/features/expenses/presentation/expenses_page.dart';
import 'package:smartbudget/features/financial_health/presentation/financial_health_page.dart';
import 'package:smartbudget/features/goals/presentation/goals_page.dart';
import 'package:smartbudget/features/income/presentation/income_page.dart';
import 'package:smartbudget/features/monthly_budget/presentation/monthly_budget_page.dart';
import 'package:smartbudget/features/reports/presentation/reports_page.dart';
import 'package:smartbudget/features/settings/presentation/settings_page.dart';
import 'package:smartbudget/features/shell/app_shell.dart';
import 'package:smartbudget/features/shell/nav_destinations.dart';
import 'package:smartbudget/features/shell/placeholder_page.dart';
import 'package:smartbudget/features/shell/splash_page.dart';
import 'package:smartbudget/features/support/presentation/support_page.dart';
import 'package:smartbudget/features/transactions/presentation/transactions_page.dart';
import 'package:smartbudget/features/zakat/presentation/zakat_page.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Public auth routes (no shell, no guard-away).
const Set<String> _authRoutes = <String>{'/login', '/signup', '/forgot'};

/// Builds the router with an auth guard driven by [authControllerProvider].
///
/// - unknown        → splash ('/')
/// - unauthenticated → redirected to '/login'
/// - authenticated   → redirected away from auth routes to '/dashboard'
GoRouter buildRouter(Ref ref) {
  // Bridge Riverpod auth changes to go_router's refresh mechanism.
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthStatus status = ref.read(authControllerProvider).status;
      final String loc = state.matchedLocation;
      final bool onAuth = _authRoutes.contains(loc);
      final bool onSplash = loc == '/';

      return switch (status) {
        AuthStatus.unknown => onSplash ? null : '/',
        AuthStatus.unauthenticated => onAuth ? null : '/login',
        AuthStatus.authenticated => (onAuth || onSplash) ? '/dashboard' : null,
      };
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordPage()),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/dashboard',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: DashboardPage()),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: TransactionsPage()),
          ),
          GoRoute(
            path: '/income',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: IncomePage()),
          ),
          GoRoute(
            path: '/expenses',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: ExpensesPage()),
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: MonthlyBudgetPage()),
          ),
          GoRoute(
            path: '/goals',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: GoalsPage()),
          ),
          GoRoute(
            path: '/debts',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: DebtsPage()),
          ),
          GoRoute(
            path: '/health',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: FinancialHealthPage()),
          ),
          GoRoute(
            path: '/exchange-rates',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: ExchangeRatesPage()),
          ),
          GoRoute(
            path: '/zakat',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: ZakatPage()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: ReportsPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: SettingsPage()),
          ),
          GoRoute(
            path: '/support',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                const NoTransitionPage<void>(child: SupportPage()),
          ),
          ..._placeholderRoutes(),
        ],
      ),
    ],
  );
}

/// Sections that already have real screens (excluded from placeholder routes).
const Set<AppSection> _implementedSections = <AppSection>{
  AppSection.dashboard,
  AppSection.transactions,
  AppSection.income,
  AppSection.expenses,
  AppSection.monthlyBudget,
  AppSection.goals,
  AppSection.debts,
  AppSection.financialHealth,
  AppSection.exchangeRates,
  AppSection.zakat,
  AppSection.reports,
  AppSection.settings,
  AppSection.helpSupport,
};

Iterable<GoRoute> _placeholderRoutes() {
  return AppNav.destinations
      .where((NavDestination d) => !_implementedSections.contains(d.section))
      .map(
        (NavDestination d) => GoRoute(
          path: d.route,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final AppLocalizations l = AppLocalizations.of(context);
            return NoTransitionPage<void>(
              child: PlaceholderPage(title: d.label(l), message: l.comingSoon),
            );
          },
        ),
      );
}
