import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/application/backup_export.dart';
import 'package:smartbudget/features/backup/application/backup_status_controller.dart';
import 'package:smartbudget/features/backup/domain/backup_reminder.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Dashboard nudge to download a backup when the data hasn't been backed up
/// for a while. One tap exports; "Later" hides it for a week.
class BackupReminderCard extends ConsumerStatefulWidget {
  const BackupReminderCard({super.key});

  @override
  ConsumerState<BackupReminderCard> createState() => _BackupReminderCardState();
}

class _BackupReminderCardState extends ConsumerState<BackupReminderCard> {
  bool _busy = false;

  Future<void> _backUp() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await exportFullBackup(ref);
      messenger.showSnackBar(SnackBar(content: Text(l.backupDone)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.backupFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(backupReminderDueProvider)) return const SizedBox.shrink();

    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final int? days = BackupReminder.daysSince(
        ref.watch(backupStatusProvider)?.lastBackup, DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.xl),
      child: GlassCard(
        accent: c.saving,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.cloud_download_outlined, color: c.saving),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    days == null
                        ? l.backupReminderNever
                        : l.backupReminderDays(days),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(l.backupReminderWhy,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                  const SizedBox(height: DsSpacing.md),
                  Wrap(
                    spacing: DsSpacing.sm,
                    runSpacing: DsSpacing.sm,
                    children: <Widget>[
                      DsButton(
                        label: l.backupNow,
                        icon: Icons.download_rounded,
                        onPressed: _busy ? null : _backUp,
                      ),
                      DsButton(
                        label: l.backupLater,
                        variant: DsButtonVariant.ghost,
                        onPressed: _busy
                            ? null
                            : () => ref
                                .read(backupStatusProvider.notifier)
                                .snooze(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
