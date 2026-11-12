import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/billing/application/trial_reminder_controller.dart';
import 'package:smartbudget/features/billing/domain/trial_reminder.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Near the end of the free PRO trial: a note at the top that says how long
/// is left and that the data stays. It can be closed; each reminder shows
/// once. On the website a tap opens the plans; the store app has no plans to
/// open (it names no price and links to no payment), so there it is text only.
class TrialReminderBanner extends ConsumerWidget {
  const TrialReminderBanner({
    super.key,
    required this.router,
    required this.child,
  });

  /// The app's router: this sits above the navigator, so it can't look it up.
  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TrialReminder? r = ref.watch(trialReminderProvider);
    final String? id = ref.watch(trialReminderIdProvider);
    if (r == null || id == null) return child;
    if (ref.watch(trialReminderDismissedProvider).contains(id)) return child;

    final AppLocalizations l = AppLocalizations.of(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String text = r.kind == TrialReminderKind.endsToday
        ? l.trialEndsToday
        : l.trialEndingSoon(r.daysLeft);
    final bool opensPlans = !AppEnv.storeFreeMode;
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 36, 12, 0),
                child: Material(
                  color: cs.inverseSurface,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: opensPlans ? () => router.push('/plans') : null,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          14, 4, 4, 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.hourglass_bottom_rounded,
                              size: 18, color: cs.onInverseSurface),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onInverseSurface)),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: cs.onInverseSurface),
                            onPressed: () => ref
                                .read(trialReminderDismissedProvider.notifier)
                                .dismiss(id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
