import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Settings — appearance (theme), language, base currency, and About.
///
/// This screen only wires existing per-viewer preference controllers; it holds
/// NO financial logic. Changing the base currency is a display/settings choice
/// (single base currency per user — cross-currency conversion is a later phase).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final ThemeMode mode = ref.watch(themeModeProvider);
    final Locale locale = ref.watch(localeProvider);
    final String base = ref.watch(baseCurrencyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l.pageSettings,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: DsSpacing.xl),

              // Appearance — theme.
              _SettingsSection(
                icon: Icons.palette_outlined,
                title: l.settingsAppearance,
                child: _SegmentedRow<ThemeMode>(
                  value: mode,
                  options: <_Segment<ThemeMode>>[
                    _Segment<ThemeMode>(ThemeMode.dark, l.themeDark,
                        Icons.dark_mode_outlined),
                    _Segment<ThemeMode>(ThemeMode.light, l.themeLight,
                        Icons.light_mode_outlined),
                    _Segment<ThemeMode>(ThemeMode.system, l.themeSystem,
                        Icons.brightness_auto_outlined),
                  ],
                  onChanged: (ThemeMode m) =>
                      ref.read(themeModeProvider.notifier).set(m),
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Language.
              _SettingsSection(
                icon: Icons.translate_outlined,
                title: l.settingsLanguage,
                child: _SegmentedRow<String>(
                  value: locale.languageCode,
                  options: <_Segment<String>>[
                    _Segment<String>('ar', l.langArabic, null),
                    _Segment<String>('en', l.langEnglish, null),
                  ],
                  onChanged: (String code) => ref
                      .read(localeProvider.notifier)
                      .set(Locale(code)),
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Region & currency.
              _SettingsSection(
                icon: Icons.attach_money_outlined,
                title: l.settingsRegion,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.baseCurrency,
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(l.baseCurrencyHint,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: DsSpacing.md),
                    _CurrencyDropdown(
                      value: base,
                      onChanged: (String v) =>
                          ref.read(baseCurrencyProvider.notifier).set(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // About.
              _SettingsSection(
                icon: Icons.info_outline_rounded,
                title: l.settingsAbout,
                child: Column(
                  children: <Widget>[
                    _AboutRow(
                      label: l.aboutAppName,
                      value: '${AppConfig.parentBrand} · ${AppConfig.appName}',
                    ),
                    _AboutRow(label: l.aboutVersion, value: AppConfig.version),
                    _AboutRow(
                        label: l.aboutBackend, value: AppEnv.backendLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: c.brand),
              const SizedBox(width: DsSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: DsSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _Segment<T> {
  const _Segment(this.value, this.label, this.icon);
  final T value;
  final String label;
  final IconData? icon;
}

/// A lightweight pill segmented control (wraps on narrow widths).
class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<_Segment<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Wrap(
      spacing: DsSpacing.sm,
      runSpacing: DsSpacing.sm,
      children: <Widget>[
        for (final _Segment<T> opt in options)
          _SegmentChip(
            label: opt.label,
            icon: opt.icon,
            selected: opt.value == value,
            onTap: () => onChanged(opt.value),
            colors: c,
          ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final DsColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.brand : colors.surfaceMuted,
      borderRadius: DsRadius.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.lg, vertical: DsSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon,
                    size: 16,
                    color: selected ? colors.onBrand : colors.textMuted),
                const SizedBox(width: DsSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? colors.onBrand : colors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: c.textMuted)),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        dropdownColor: c.bgElevated,
        items: <DropdownMenuItem<String>>[
          for (final Currency cur in Currencies.all)
            DropdownMenuItem<String>(
              value: cur.code,
              child: Text('${cur.code} · ${cur.symbol}'),
            ),
        ],
        onChanged: (String? v) => v == null ? null : onChanged(v),
      ),
    );
  }
}
