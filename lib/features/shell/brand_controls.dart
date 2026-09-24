import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Light/Dark toggle — flips theme instantly (no reload) and persists.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final bool isDark = mode == ThemeMode.dark;
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);

    return IconButton(
      tooltip: l.themeToggleTooltip,
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: c.brand,
        size: 20,
      ),
    );
  }
}

/// Arabic/English toggle — flips locale (and RTL/LTR) instantly and persists.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      icon: Icon(Icons.translate_outlined, size: 18, color: c.brand),
      label: Text(l.languageToggleTooltip, style: TextStyle(color: c.textMuted)),
      style: TextButton.styleFrom(foregroundColor: c.textMuted),
    );
  }
}
