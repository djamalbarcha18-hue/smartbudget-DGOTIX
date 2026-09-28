import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/domain/lock_config.dart';
import 'package:smartbudget/features/app_lock/presentation/pin_setup_sheet.dart';
import 'package:smartbudget/features/app_lock/presentation/recovery_code_view.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/backup/application/backup_status_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Settings → App lock.
class AppLockSection extends ConsumerWidget {
  const AppLockSection({super.key});

  void _say(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final LockConfig cfg = ref.watch(appLockProvider).config;
    final AppLockController ctrl = ref.read(appLockProvider.notifier);

    if (!cfg.enabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.lockHint, style: t.bodySmall?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.sm),
          _BackupAdvice(last: ref.watch(backupStatusProvider)?.lastBackup),
          const SizedBox(height: DsSpacing.md),
          DsButton(
            label: l.lockEnable,
            icon: Icons.lock_outline_rounded,
            onPressed: () async {
              final String? pin =
                  await PinSetupSheet.show(context, PinSheetMode.create);
              if (pin == null) return;
              final String code = await ctrl.enable(pin);
              if (context.mounted) await RecoveryCodeSheet.show(context, code);
              if (context.mounted) _say(context, l.pinSaved);
            },
          ),
        ],
      );
    }

    final bool? deviceAvailable =
        ref.watch(deviceAuthAvailableProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(DsSpacing.md),
          decoration: BoxDecoration(
            color: c.income.withValues(alpha: 0.10),
            borderRadius: DsRadius.brMd,
            border: Border.all(color: c.income.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.verified_user_rounded, color: c.income, size: 20),
              const SizedBox(width: DsSpacing.md),
              Expanded(child: Text(l.lockOn, style: t.titleSmall)),
            ],
          ),
        ),
        const SizedBox(height: DsSpacing.md),

        // Recovery code for a forgotten PIN.
        Row(
          children: <Widget>[
            Icon(Icons.key_rounded,
                color: cfg.hasRecovery ? c.brand : c.warning, size: 22),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l.lockRecoveryTitle, style: t.titleSmall),
                  Text(
                      cfg.hasRecovery
                          ? l.lockRecoveryStatusOn
                          : l.lockRecoveryStatusOff,
                      style: t.bodySmall?.copyWith(
                          color: cfg.hasRecovery ? c.textMuted : c.warning)),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final String? ok =
                    await PinSetupSheet.show(context, PinSheetMode.verify);
                if (ok == null) return;
                final bool replaced = cfg.hasRecovery;
                final String code = await ctrl.newRecoveryCode();
                if (context.mounted) {
                  await RecoveryCodeSheet.show(context, code,
                      replaced: replaced);
                }
              },
              child: Text(l.lockRecoveryNew),
            ),
          ],
        ),
        const SizedBox(height: DsSpacing.lg),

        // Unlock with the device.
        Row(
          children: <Widget>[
            Icon(Icons.fingerprint_rounded, color: c.brand, size: 22),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l.lockDevice, style: t.titleSmall),
                  Text(
                      deviceAvailable == false
                          ? l.lockDeviceUnavailable
                          : l.lockDeviceHint,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            Switch(
              value: cfg.deviceUnlock,
              onChanged: deviceAvailable != true
                  ? null
                  : (bool on) async {
                      if (!on) {
                        await ctrl.disableDeviceUnlock();
                        return;
                      }
                      final String name =
                          ref.read(authControllerProvider).user?.email ??
                              'SmartBudget';
                      final bool ok = await ctrl.enableDeviceUnlock(name);
                      if (context.mounted) {
                        _say(context,
                            ok ? l.lockDeviceOn : l.lockDeviceSetupFailed);
                      }
                    },
            ),
          ],
        ),
        const SizedBox(height: DsSpacing.lg),

        // Auto-lock delay.
        Text(l.lockAutoAfter, style: t.titleSmall),
        const SizedBox(height: DsSpacing.sm),
        Wrap(
          spacing: DsSpacing.sm,
          runSpacing: DsSpacing.sm,
          children: <Widget>[
            for (final int m in LockConfig.autoLockChoices)
              ChoiceChip(
                label: Text(m == 0 ? l.lockImmediately : l.clockMinutes(m)),
                selected: cfg.autoLockMinutes == m,
                onSelected: (_) => ctrl.setAutoLock(m),
              ),
          ],
        ),
        const SizedBox(height: DsSpacing.lg),
        Wrap(
          spacing: DsSpacing.sm,
          runSpacing: DsSpacing.sm,
          children: <Widget>[
            DsButton(
              label: l.lockNow,
              icon: Icons.lock_rounded,
              onPressed: ctrl.lock,
            ),
            DsButton(
              label: l.lockChangePin,
              icon: Icons.password_rounded,
              variant: DsButtonVariant.secondary,
              onPressed: () async {
                final String? pin =
                    await PinSetupSheet.show(context, PinSheetMode.change);
                if (pin == null) return;
                await ctrl.setPin(pin);
                if (context.mounted) _say(context, l.pinSaved);
              },
            ),
            DsButton(
              label: l.lockDisable,
              icon: Icons.lock_open_rounded,
              variant: DsButtonVariant.ghost,
              onPressed: () async {
                final String? ok =
                    await PinSetupSheet.show(context, PinSheetMode.verify);
                if (ok == null) return;
                await ctrl.disable();
                if (context.mounted) _say(context, l.lockDisabledMsg);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Before turning the lock on: a backup is what saves the data if both the
/// PIN and the recovery code are lost.
class _BackupAdvice extends StatelessWidget {
  const _BackupAdvice({required this.last});
  final DateTime? last;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final DateTime? d = last;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(d == null ? Icons.info_outline_rounded : Icons.cloud_done_outlined,
            size: 18, color: d == null ? c.warning : c.income),
        const SizedBox(width: DsSpacing.sm),
        Expanded(
          child: Text(
            d == null ? l.lockBackupFirst : l.lockBackupLastShort(isoDate(d)),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: d == null ? c.warning : c.textMuted),
          ),
        ),
      ],
    );
  }
}
