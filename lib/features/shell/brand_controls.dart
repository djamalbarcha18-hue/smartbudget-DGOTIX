import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/features/settings/presentation/language_picker.dart';
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

/// The current language's own name; opens [LanguagePicker], which switches
/// the locale (and RTL/LTR) smoothly and persists it.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  static String nativeName(String code) => AppLang.fromCode(code).nativeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final String current = ref.watch(localeProvider).languageCode;
    return InkWell(
      borderRadius: DsRadius.brMd,
      onTap: () => LanguagePicker.show(context),
      child: Tooltip(
        message: l.settingsLanguage,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.translate_outlined, size: 18, color: c.brand),
            const SizedBox(width: 6),
            Text(nativeName(current), style: TextStyle(color: c.textMuted)),
          ],
        ),
      ),
      ),
    );
  }
}
