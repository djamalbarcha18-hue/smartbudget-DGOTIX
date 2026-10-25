import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/quick_entry/presentation/quick_entry_sheet.dart';
import 'package:smartbudget/features/reminders/application/reminder_controller.dart';
import 'package:smartbudget/features/reminders/data/reminder_notifications.dart';
import 'package:smartbudget/features/reminders/domain/daily_reminder.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Settings: the daily reminder's switch and time (Android app only).
class ReminderSection extends ConsumerStatefulWidget {
  const ReminderSection({super.key});

  @override
  ConsumerState<ReminderSection> createState() => _ReminderSectionState();
}

class _ReminderSectionState extends ConsumerState<ReminderSection> {
  /// The phone refused notifications when the user turned the reminder on.
  bool _blocked = false;

  Future<void> _toggle(bool on) async {
    final bool ok = await ref.read(reminderProvider.notifier).setEnabled(on);
    if (mounted) setState(() => _blocked = on && !ok);
  }

  Future<void> _pickTime(ReminderSettings s) async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (t != null) {
      await ref.read(reminderProvider.notifier).setTime(t.hour, t.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final ReminderSettings s = ref.watch(reminderProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.reminderHint, style: t.bodySmall?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.sm),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: s.enabled,
          onChanged: _toggle,
          title: Text(l.reminderEnable, style: t.titleSmall),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: s.enabled
              ? Row(
                  children: <Widget>[
                    Icon(Icons.schedule_rounded, size: 18, color: c.textMuted),
                    const SizedBox(width: DsSpacing.sm),
                    Expanded(child: Text(l.reminderTime, style: t.bodyMedium)),
                    Material(
                      color: c.surfaceMuted,
                      borderRadius: DsRadius.brMd,
                      child: InkWell(
                        borderRadius: DsRadius.brMd,
                        onTap: () => _pickTime(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DsSpacing.lg, vertical: DsSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: DsRadius.brMd,
                            border: Border.all(color: c.border),
                          ),
                          child: Text(
                            s.timeLabel,
                            textDirection: TextDirection.ltr,
                            style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700, color: c.brand),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
        if (_blocked) ...<Widget>[
          const SizedBox(height: DsSpacing.sm),
          Text(l.reminderPermissionDenied,
              style: t.bodySmall?.copyWith(color: c.warning)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () =>
                  ReminderNotifications.instance.openSystemSettings(),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text(l.actionOpenSettings),
            ),
          ),
        ],
      ],
    );
  }
}

/// Opens quick entry when the user taps the reminder (also one that opened
/// the app). Sits in the app shell, so it waits for sign-in and the lock.
class ReminderTapListener extends StatefulWidget {
  const ReminderTapListener({super.key, required this.child, this.onOpen});

  final Widget child;

  /// What a tap opens; quick entry unless a test says otherwise.
  final void Function(BuildContext context)? onOpen;

  @override
  State<ReminderTapListener> createState() => _ReminderTapListenerState();
}

class _ReminderTapListenerState extends State<ReminderTapListener> {
  @override
  void initState() {
    super.initState();
    ReminderNotifications.tapped.addListener(_onTap);
    // A tap that launched the app came before this was built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTap());
  }

  @override
  void dispose() {
    ReminderNotifications.tapped.removeListener(_onTap);
    super.dispose();
  }

  void _onTap() {
    if (!mounted || !ReminderNotifications.tapped.value) return;
    ReminderNotifications.tapped.value = false;
    (widget.onOpen ?? QuickEntrySheet.show)(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
