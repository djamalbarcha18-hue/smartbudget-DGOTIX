import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/core/time/clock_sync_controller.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/features/app_lock/presentation/app_lock_gate.dart';
import 'package:smartbudget/features/shell/offline_banner.dart';
import 'package:smartbudget/features/sync/application/sync_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/shell/update_banner.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Single router instance for the app lifetime (auth-guarded).
final _routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

/// Root widget. Wires theme (dark/light, no reload), locale (RTL/LTR
/// flips automatically), and routing. Business logic lives in features, never
/// here.
class SmartBudgetApp extends ConsumerWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale locale = ref.watch(localeProvider);
    final AppLang lang = AppLang.fromCode(locale.languageCode);
    final GoRouter router = ref.watch(_routerProvider);
    // Keeps the periodic world-time sync running for the app's lifetime.
    ref.listen(clockSyncProvider, (_, __) {});
    // Gives older foreign-currency transactions their base-currency value.
    ref.listen(baseValueBackfillProvider, (_, __) {});
    // Keeps this device and the account's cloud copy in step.
    ref.listen(syncControllerProvider, (_, __) {});
    // Until the user picks a base currency, it follows the language (Turkish
    // shows lira, Malay ringgit…); the first transaction settles it.
    ref.listen(localeProvider, (Locale? prev, Locale next) {
      if (prev?.languageCode != next.languageCode) {
        ref
            .read(baseCurrencyProvider.notifier)
            .followLanguage(AppLang.fromCode(next.languageCode));
      }
    });
    ref.listen(transactionsProvider, (_, AsyncValue<List<Transaction>> next) {
      if (next.valueOrNull?.isNotEmpty ?? false) {
        ref.read(baseCurrencyProvider.notifier).keep().ignore();
      }
    });

    return MaterialApp.router(
      title: '${AppConfig.appName} — by ${AppConfig.parentBrand}',
      debugShowCheckedModeBanner: false,
      // Urdu swaps the font family (DsTypography), so the theme follows the
      // language.
      theme: DsTheme.light(lang: lang),
      darkTheme: DsTheme.dark(lang: lang),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) => AppLockGate(
          child: OfflineBanner(
              child: UpdateBanner(child: child ?? const SizedBox.shrink()))),
    );
  }
}
