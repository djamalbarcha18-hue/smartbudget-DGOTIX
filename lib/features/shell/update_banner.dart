import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/update/app_update.dart';
import 'package:smartbudget/core/update/page_reload.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Shows "A new version is available · Update" over the app once a newer
/// build is deployed; Update reloads the page into it.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool available = ref.watch(appUpdateAvailableProvider);
    if (!available) return child;
    final DsColors c = context.dsColors;
    final AppLocalizations l = AppLocalizations.of(context);
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          left: DsSpacing.md,
          right: DsSpacing.md,
          bottom: DsSpacing.md + MediaQuery.paddingOf(context).bottom,
          child: Center(
            child: Material(
              color: c.bgElevated,
              elevation: 6,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    DsSpacing.md, DsSpacing.xs, DsSpacing.xs, DsSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.system_update_alt_rounded, size: 20, color: c.brand),
                    const SizedBox(width: DsSpacing.sm),
                    Flexible(
                      child: Text(l.updateAvailable,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: c.textPrimary)),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    FilledButton(
                      onPressed: reloadPage,
                      child: Text(l.updateNow),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
