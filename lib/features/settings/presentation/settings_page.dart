import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/core/money/currency.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/theme/theme_controller.dart';
import 'package:smartbudget/design_system/components/currency_flag.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/application/backup_controller.dart';
import 'package:smartbudget/features/backup/application/cloud_backup_controller.dart';
import 'package:smartbudget/features/backup/data/cloud_backup_service.dart';
import 'package:smartbudget/features/backup/data/file_io.dart';
import 'package:smartbudget/features/backup/domain/backup_model.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/budget/application/budget_controller.dart';
import 'package:smartbudget/features/dev/sample_data_controller.dart';
import 'package:smartbudget/features/receipts/application/receipt_scan_controller.dart';
import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
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

              // Custom categories.
              _SettingsSection(
                icon: Icons.category_outlined,
                title: l.settingsCategories,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(l.categoriesManageHint,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: DsSpacing.lg),
                    _CategoryManager(
                      title: l.customIncomeCategories,
                      type: TransactionType.income,
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    _CategoryManager(
                      title: l.customExpenseCategories,
                      type: TransactionType.expense,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Data — backup & restore.
              _SettingsSection(
                icon: Icons.backup_outlined,
                title: l.settingsData,
                child: const _BackupSection(),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Cloud backup (sync) — only with a real backend.
              if (AppEnv.hasSupabase) ...<Widget>[
                _SettingsSection(
                  icon: Icons.cloud_sync_outlined,
                  title: l.cloudBackupTitle,
                  child: const _CloudBackupSection(),
                ),
                const SizedBox(height: DsSpacing.lg),
              ],

              // Developer — sample data for testing the template.
              _SettingsSection(
                icon: Icons.science_outlined,
                title: l.settingsDeveloper,
                child: const _DeveloperSection(),
              ),
              const SizedBox(height: DsSpacing.lg),

              // Receipt scanning (BYOK Gemini key) — only with a real backend.
              if (AppEnv.hasSupabase) ...<Widget>[
                _SettingsSection(
                  icon: Icons.document_scanner_outlined,
                  title: l.settingsReceiptScanning,
                  child: const _ReceiptKeySection(),
                ),
                const SizedBox(height: DsSpacing.lg),
              ],

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

/// Developer tools: load deterministic 2026 sample data to test the template.
class _DeveloperSection extends ConsumerStatefulWidget {
  const _DeveloperSection();

  @override
  ConsumerState<_DeveloperSection> createState() => _DeveloperSectionState();
}

class _DeveloperSectionState extends ConsumerState<_DeveloperSection> {
  bool _busy = false;

  Future<void> _loadSample() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final SampleImportResult res =
          await ref.read(sampleDataLoaderProvider).load(year: 2026);
      messenger.showSnackBar(SnackBar(
        content: Text(res.isEmpty
            ? l.importEmpty
            : l.importDone(res.transactionsAdded, res.budgetsAdded)),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearSample() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final SampleImportResult res =
          await ref.read(sampleDataLoaderProvider).clear(year: 2026);
      messenger.showSnackBar(SnackBar(
        content: Text(res.isEmpty
            ? l.sampleDataNone
            : l.sampleDataCleared(res.transactionsAdded, res.budgetsAdded)),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.sampleDataHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: DsSpacing.md),
        Wrap(
          spacing: DsSpacing.sm,
          runSpacing: DsSpacing.sm,
          children: <Widget>[
            DsButton(
              label: l.loadSampleData,
              icon: Icons.auto_awesome_outlined,
              variant: DsButtonVariant.secondary,
              onPressed: _busy ? null : _loadSample,
            ),
            DsButton(
              label: l.clearSampleData,
              icon: Icons.delete_sweep_outlined,
              variant: DsButtonVariant.ghost,
              onPressed: _busy ? null : _clearSample,
            ),
          ],
        ),
      ],
    );
  }
}

/// BYOK: the signed-in user stores their own Gemini API key (encrypted in
/// Supabase) so the receipt scanner can call Gemini on their behalf.
class _ReceiptKeySection extends ConsumerStatefulWidget {
  const _ReceiptKeySection();

  @override
  ConsumerState<_ReceiptKeySection> createState() => _ReceiptKeySectionState();
}

class _ReceiptKeySectionState extends ConsumerState<_ReceiptKeySection> {
  final TextEditingController _ctrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String key = _ctrl.text.trim();
    if (key.isEmpty) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(geminiKeyServiceProvider).save(key);
      _ctrl.clear();
      ref.invalidate(geminiKeyStatusProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.receiptKeySaved)));
    } on ReceiptScanException {
      messenger.showSnackBar(SnackBar(content: Text(l.receiptErrInvalidKey)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(geminiKeyServiceProvider).remove();
      ref.invalidate(geminiKeyStatusProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.receiptKeyRemoved)));
    } catch (_) {
      // Non-fatal; status refresh below reflects reality.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool signedIn = ref.watch(authControllerProvider).isAuthenticated;

    if (!signedIn) {
      return Text(l.receiptErrSignIn,
          style: Theme.of(context).textTheme.bodySmall);
    }

    final AsyncValue<bool> status = ref.watch(geminiKeyStatusProvider);
    final bool hasKey = status.valueOrNull ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.receiptKeyHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: DsSpacing.md),
        Row(
          children: <Widget>[
            Icon(hasKey ? Icons.check_circle_outline : Icons.info_outline,
                size: 16, color: hasKey ? c.income : c.textMuted),
            const SizedBox(width: DsSpacing.sm),
            Text(hasKey ? l.receiptKeySet : l.receiptKeyNotSet,
                style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: DsSpacing.md),
        TextField(
          controller: _ctrl,
          obscureText: _obscure,
          enabled: !_busy,
          decoration: InputDecoration(
            isDense: true,
            hintText: l.receiptKeyField,
            filled: true,
            fillColor: c.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md, vertical: DsSpacing.sm),
            enabledBorder: OutlineInputBorder(
              borderRadius: DsRadius.brMd,
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DsRadius.brMd,
              borderSide: BorderSide(color: c.brand),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: c.textMuted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        Wrap(
          spacing: DsSpacing.sm,
          runSpacing: DsSpacing.sm,
          children: <Widget>[
            DsButton(
              label: l.save,
              variant: DsButtonVariant.primary,
              onPressed: _busy ? null : _save,
            ),
            if (hasKey)
              DsButton(
                label: l.receiptKeyRemove,
                variant: DsButtonVariant.secondary,
                onPressed: _busy ? null : _remove,
              ),
          ],
        ),
      ],
    );
  }
}

/// Export a full backup (JSON) or transactions (CSV), and restore from a
/// backup file — all on-device, no server required.
class _BackupSection extends ConsumerStatefulWidget {
  const _BackupSection();

  @override
  ConsumerState<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<_BackupSection> {
  bool _busy = false;

  String _stamp() {
    final DateTime n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}-${two(n.hour)}${two(n.minute)}';
  }

  Future<void> _exportJson() async {
    final BackupService svc = ref.read(backupServiceProvider);
    await downloadText(
      filename: 'smartbudget-backup-${_stamp()}.json',
      text: svc.exportJson(),
      mime: 'application/json;charset=utf-8',
    );
  }

  Future<void> _exportCsv() async {
    final BackupService svc = ref.read(backupServiceProvider);
    // BOM so Excel reads UTF-8 (Arabic) correctly.
    await downloadText(
      filename: 'smartbudget-transactions-${_stamp()}.csv',
      text: '﻿${svc.exportTransactionsCsv()}',
      mime: 'text/csv;charset=utf-8',
    );
  }

  Future<void> _import() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final String? raw = await pickTextFile();
      if (raw == null) return; // user cancelled
      final ImportResult res =
          await ref.read(backupServiceProvider).importJson(raw);
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.isEmpty
              ? l.importEmpty
              : l.importDone(res.transactionsAdded, res.budgetsAdded)),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    // Watch so the underlying stores stay loaded while this screen is open.
    final int txCount =
        ref.watch(transactionsProvider).valueOrNull?.length ?? 0;
    final int budCount = ref.watch(budgetsProvider).valueOrNull?.length ?? 0;
    final bool hasData = txCount > 0 || budCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.dataBackupHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: DsSpacing.lg),
        Wrap(
          spacing: DsSpacing.sm,
          runSpacing: DsSpacing.sm,
          children: <Widget>[
            _ActionButton(
              icon: Icons.download_outlined,
              label: l.exportJson,
              onTap: _busy || !hasData ? null : _exportJson,
            ),
            _ActionButton(
              icon: Icons.table_chart_outlined,
              label: l.exportCsv,
              onTap: _busy || txCount == 0 ? null : _exportCsv,
            ),
            _ActionButton(
              icon: Icons.upload_file_outlined,
              label: l.importJson,
              onTap: _busy ? null : _import,
            ),
          ],
        ),
        if (!hasData) ...<Widget>[
          const SizedBox(height: DsSpacing.sm),
          Text(l.exportEmpty,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: c.textFaint)),
        ],
      ],
    );
  }
}

/// Sync a full backup to the signed-in user's account and restore it on any
/// device. Storage is guarded by Supabase RLS (each user sees only their row).
class _CloudBackupSection extends ConsumerStatefulWidget {
  const _CloudBackupSection();

  @override
  ConsumerState<_CloudBackupSection> createState() =>
      _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<_CloudBackupSection> {
  bool _busy = false;

  Future<void> _backUp() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final Map<String, dynamic> data =
          ref.read(backupServiceProvider).snapshot().toJson();
      await ref
          .read(cloudBackupServiceProvider)
          .push(data, BackupData.schemaVersion);
      ref.invalidate(cloudBackupMetaProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.cloudBackedUp)));
    } on CloudBackupException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.kind == CloudBackupErrorKind.notSignedIn
            ? l.cloudBackupSignIn
            : l.cloudFailed),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final Map<String, dynamic>? data =
          await ref.read(cloudBackupServiceProvider).pull();
      if (data == null) {
        messenger.showSnackBar(SnackBar(content: Text(l.cloudNoBackup)));
        return;
      }
      final ImportResult res = await ref
          .read(backupServiceProvider)
          .importData(BackupData.fromJson(data));
      messenger.showSnackBar(SnackBar(
        content: Text(res.isEmpty
            ? l.importEmpty
            : l.importDone(res.transactionsAdded, res.budgetsAdded)),
      ));
    } on CloudBackupException {
      messenger.showSnackBar(SnackBar(content: Text(l.cloudFailed)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmt(DateTime d) {
    final DateTime x = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${x.year}-${two(x.month)}-${two(x.day)} ${two(x.hour)}:${two(x.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final bool signedIn = ref.watch(authControllerProvider).isAuthenticated;

    if (!signedIn) {
      return Text(l.cloudBackupSignIn,
          style: Theme.of(context).textTheme.bodySmall);
    }

    final AsyncValue<CloudBackupMeta?> meta =
        ref.watch(cloudBackupMetaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.cloudBackupHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: DsSpacing.md),
        Row(
          children: <Widget>[
            Icon(
              meta.valueOrNull != null
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              size: 16,
              color: meta.valueOrNull != null ? c.income : c.textMuted,
            ),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Text(
                switch (meta) {
                  AsyncData<CloudBackupMeta?>(value: final CloudBackupMeta? m) =>
                    m == null
                        ? l.cloudNeverSynced
                        : l.cloudLastSynced(_fmt(m.updatedAt)),
                  AsyncError<CloudBackupMeta?>() => l.cloudFailed,
                  _ => l.cloudSyncing,
                },
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: DsSpacing.lg),
        Wrap(
          spacing: DsSpacing.sm,
          runSpacing: DsSpacing.sm,
          children: <Widget>[
            _ActionButton(
              icon: Icons.cloud_upload_outlined,
              label: l.cloudBackUp,
              onTap: _busy ? null : _backUp,
            ),
            _ActionButton(
              icon: Icons.cloud_download_outlined,
              label: l.cloudRestore,
              onTap: _busy ? null : _restore,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final bool enabled = onTap != null;
    return Material(
      color: enabled ? c.surfaceMuted : c.surfaceMuted.withValues(alpha: 0.5),
      borderRadius: DsRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.lg, vertical: DsSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon,
                  size: 18, color: enabled ? c.brand : c.textFaint),
              const SizedBox(width: DsSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: enabled ? c.textPrimary : c.textFaint,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add/remove user-defined categories for one [TransactionType].
class _CategoryManager extends ConsumerStatefulWidget {
  const _CategoryManager({required this.title, required this.type});
  final String title;
  final TransactionType type;

  @override
  ConsumerState<_CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends ConsumerState<_CategoryManager> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final String name = _ctrl.text.trim();
    if (name.isEmpty) return;
    ref.read(customCategoriesProvider.notifier).add(widget.type, name);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    final List<String> items =
        ref.watch(customCategoriesProvider).forType(widget.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: DsSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.addCategoryHint,
                  filled: true,
                  fillColor: c.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.md, vertical: DsSpacing.sm),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: DsRadius.brMd,
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: DsRadius.brMd,
                    borderSide: BorderSide(color: c.brand),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DsSpacing.sm),
            Material(
              color: c.brand,
              borderRadius: DsRadius.brMd,
              child: InkWell(
                onTap: _add,
                borderRadius: DsRadius.brMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.lg, vertical: DsSpacing.md),
                  child: Text(l.addCategory,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: c.onBrand)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DsSpacing.sm),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs),
            child: Text(l.noCustomCategories,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: c.textFaint)),
          )
        else
          Wrap(
            spacing: DsSpacing.sm,
            runSpacing: DsSpacing.sm,
            children: <Widget>[
              for (final String name in items)
                Chip(
                  label: Text(name),
                  backgroundColor: c.surfaceMuted,
                  side: BorderSide(color: c.border),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  deleteButtonTooltipMessage: l.removeCategory,
                  onDeleted: () => ref
                      .read(customCategoriesProvider.notifier)
                      .remove(widget.type, name),
                ),
            ],
          ),
      ],
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CurrencyFlag(cur, width: 22),
                  const SizedBox(width: DsSpacing.sm),
                  Text('${cur.code} · ${cur.symbol}'),
                ],
              ),
            ),
        ],
        onChanged: (String? v) => v == null ? null : onChanged(v),
      ),
    );
  }
}
