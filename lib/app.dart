import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/router/app_router.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/design_system/theme/ds_theme.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Single router instance for the app lifetime (auth-guarded).
final _routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

/// Root widget. Wires theme (dark/light, no reload), locale (ar/en, RTL/LTR
/// flips automatically), and routing. Business logic lives in features, never
/// here.
class SmartBudgetApp extends ConsumerWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale locale = ref.watch(localeProvider);
    final GoRouter router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: '${AppConfig.appName} — by ${AppConfig.parentBrand}',
      debugShowCheckedModeBanner: false,
      theme: DsTheme.light(),
      darkTheme: DsTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
