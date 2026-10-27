import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/app_restart.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// What shows instead of a part of the screen that failed to draw (in place
/// of Flutter's plain grey box, which left the app looking stuck): a short
/// line and a way home. A small spot gets only a quiet icon.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.details});

  /// What went wrong (kept for the logs; never shown).
  final FlutterErrorDetails? details;

  /// Home: closes whatever is open over the page and goes to the dashboard;
  /// already there, the app starts again cleanly (the data is kept).
  static Future<void> goHome(BuildContext context) async {
    final GoRouter? router = GoRouter.maybeOf(context);
    final String? at = router?.routerDelegate.currentConfiguration.uri.path;
    if (router == null || at == '/dashboard' || at == '/') {
      await AppRestart.run();
      return;
    }
    Navigator.of(context, rootNavigator: true)
        .popUntil((Route<dynamic> r) => r.settings is Page<dynamic>);
    router.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final ThemeData theme = Theme.of(context);
        final Color muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
        if (c.maxWidth < 180 || c.maxHeight < 120) {
          return Center(
              child: Icon(Icons.error_outline_rounded, size: 18, color: muted));
        }
        final AppLocalizations? l =
            Localizations.of<AppLocalizations>(context, AppLocalizations);
        final bool ar =
            (Localizations.maybeLocaleOf(context)?.languageCode ?? '') == 'ar';
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.error_outline_rounded, size: 28, color: muted),
                const SizedBox(height: 8),
                Text(
                  l?.errorPartTitle ??
                      (ar
                          ? 'تعذّر عرض هذا الجزء'
                          : "This part couldn't be shown"),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => goHome(context),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: Text(l?.errorGoHome ??
                      (ar ? 'رجوع إلى الرئيسية' : 'Back home')),
                ),
              ],
            ),
          ),
        );
      },
    );
    // It can be drawn anywhere, even above the app's own frame.
    return Material(
      type: MaterialType.transparency,
      child: Directionality.maybeOf(context) == null
          ? Directionality(textDirection: TextDirection.ltr, child: body)
          : body,
    );
  }
}
