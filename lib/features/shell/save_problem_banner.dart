import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/storage/save_health.dart';
import 'package:smartbudget/core/update/app_update.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/application/backup_export.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Over the app while some changes couldn't be stored on the device (see
/// [SaveHealth]): what happened, «back up now» (the backup still holds the
/// changes) and «try again». It goes away once everything is stored.
class SaveProblemBanner extends StatelessWidget {
  const SaveProblemBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SaveHealth.failing,
      child: child,
      builder: (BuildContext context, bool failing, Widget? child) {
        if (!failing) return child!;
        return Stack(
          children: <Widget>[
            child!,
            // At the bottom, so the page's own bar and menu stay reachable.
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(top: false, child: _SaveProblemCard()),
            ),
          ],
        );
      },
    );
  }
}

class _SaveProblemCard extends ConsumerStatefulWidget {
  const _SaveProblemCard();

  @override
  ConsumerState<_SaveProblemCard> createState() => _SaveProblemCardState();
}

class _SaveProblemCardState extends ConsumerState<_SaveProblemCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      // The card stays while anything is unsaved.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry() async {
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    final String done = AppLocalizations.of(context).saveRetryDone;
    if (await SaveHealth.retryAll()) {
      messenger?.showSnackBar(SnackBar(content: Text(done)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    // Above the «new version» note when both show.
    final bool update = ref.watch(appUpdateAvailableProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          DsSpacing.md, 0, DsSpacing.md, update ? 76 : DsSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: c.bgElevated,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.expense.withValues(alpha: 0.5)),
                ),
                padding: const EdgeInsets.all(DsSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.warning_amber_rounded, color: c.expense),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.saveFailedTitle,
                              style: t.titleSmall?.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(l.saveFailedWhy,
                              style: t.bodySmall?.copyWith(color: c.textMuted)),
                          const SizedBox(height: DsSpacing.sm),
                          Wrap(
                            spacing: DsSpacing.sm,
                            runSpacing: DsSpacing.xs,
                            children: <Widget>[
                              FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _run(() => exportFullBackup(ref)),
                                icon: const Icon(Icons.download_rounded,
                                    size: 18),
                                label: Text(l.backupNow),
                              ),
                              TextButton.icon(
                                onPressed: _busy ? null : () => _run(_retry),
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(l.loadRetry),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
