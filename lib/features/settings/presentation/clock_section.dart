import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/core/time/clock_format.dart';
import 'package:smartbudget/core/time/clock_sync_controller.dart';
import 'package:smartbudget/core/time/device_time_zone.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Settings → "Time & world clock": sync status, the device's drift, the
/// current local/UTC time and the time zone, plus a manual "Sync now".
class ClockSection extends ConsumerStatefulWidget {
  const ClockSection({super.key});

  @override
  ConsumerState<ClockSection> createState() => _ClockSectionState();
}

class _ClockSectionState extends ConsumerState<ClockSection> {
  late final Timer _tick;
  final String? _zone = deviceTimeZoneName();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _hm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
  static String _ymd(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  String _amount(AppLocalizations l, Duration d) {
    final ({int days, int hours, int minutes, int seconds}) p = splitDrift(d);
    final String and = l.localeName.startsWith('ar') ? ' و' : ' ';
    if (p.days > 0) {
      return p.hours > 0
          ? '${l.clockDays(p.days)}$and${l.clockHours(p.hours)}'
          : l.clockDays(p.days);
    }
    if (p.hours > 0) {
      return p.minutes > 0
          ? '${l.clockHours(p.hours)}$and${l.clockMinutes(p.minutes)}'
          : l.clockHours(p.hours);
    }
    if (p.minutes > 0) return l.clockMinutes(p.minutes);
    return l.clockSeconds(p.seconds);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final ClockStatus s = ref.watch(clockSyncProvider);

    final DateTime now = AppClock.now();
    final DateTime utc = now.toUtc();
    final String offset = formatUtcOffset(now.timeZoneOffset);
    final String zone =
        (_zone == null || _zone == 'UTC' || _zone == 'Etc/UTC')
            ? offset
            : '$_zone · $offset';

    final (IconData icon, Color color, String title) = s.syncing
        ? (Icons.sync_rounded, c.brand, l.clockSyncing)
        : s.synced
            ? (Icons.verified_rounded, c.income, l.clockSynced)
            : (Icons.sync_problem_rounded, c.warning, l.clockNotSynced);

    final String? detail = s.syncing
        ? null
        : s.failed && !s.synced
            ? l.clockSyncFailed
            : !s.synced
                ? null
                : s.offset == Duration.zero
                    ? l.clockDeviceAccurate
                    : s.offset.isNegative
                        ? l.clockDeviceAhead(_amount(l, s.offset))
                        : l.clockDeviceBehind(_amount(l, s.offset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l.clockHint, style: t.bodySmall?.copyWith(color: c.textMuted)),
        const SizedBox(height: DsSpacing.md),
        Container(
          padding: const EdgeInsets.all(DsSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: DsRadius.brMd,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: t.titleSmall?.copyWith(color: c.textPrimary)),
                    if (detail != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(detail,
                          style: t.bodySmall?.copyWith(color: c.textMuted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        _ClockRow(label: l.clockNow, value: '${_hm(now)} · ${_ymd(now)}'),
        _ClockRow(label: l.clockUtc, value: '${_hm(utc)} · ${_ymd(utc)}'),
        _ClockRow(label: l.clockTimeZone, value: zone),
        if (s.syncedAt != null)
          _ClockRow(label: l.clockLastSync, value: _hm(s.syncedAt!)),
        const SizedBox(height: DsSpacing.md),
        DsButton(
          label: l.clockSyncNow,
          icon: Icons.sync_rounded,
          variant: DsButtonVariant.secondary,
          onPressed: s.syncing
              ? null
              : () => ref.read(clockSyncProvider.notifier).syncNow(),
        ),
      ],
    );
  }
}

class _ClockRow extends StatelessWidget {
  const _ClockRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.xs + 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label,
                style: t.bodyMedium?.copyWith(color: c.textMuted)),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(value, style: t.titleSmall),
          ),
        ],
      ),
    );
  }
}
