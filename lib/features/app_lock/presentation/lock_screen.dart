import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/presentation/pin_entry.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Full-screen lock shown over the whole app while it is locked.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final GlobalKey<PinEntryState> _pin = GlobalKey<PinEntryState>();
  String? _error;
  bool _forgot = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          ref.read(appLockProvider.notifier).waitRemaining > Duration.zero) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _submit(AppLocalizations l, String pin) {
    final PinResult r = ref.read(appLockProvider.notifier).unlockWithPin(pin);
    if (r == PinResult.ok) return;
    _pin.currentState?.clear();
    setState(() => _error = r == PinResult.wrong ? l.lockWrongPin : null);
  }

  Future<void> _device(AppLocalizations l) async {
    final bool ok = await ref.read(appLockProvider.notifier).unlockWithDevice();
    if (!ok && mounted) setState(() => _error = l.lockDeviceFailed);
  }

  static String _mmss(Duration d) {
    final int s = d.inSeconds + (d.inMilliseconds % 1000 > 0 ? 1 : 0);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLockState s = ref.watch(appLockProvider);
    final Duration wait = ref.read(appLockProvider.notifier).waitRemaining;
    final bool waiting = wait > Duration.zero;

    return Material(
      color: c.bgPage,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DsSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: c.brand.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded, color: c.brand, size: 30),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  Text(l.lockTitle(AppConfig.appName),
                      textAlign: TextAlign.center,
                      style:
                          t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: DsSpacing.xs),
                  if (_forgot)
                    ..._forgotView(l, c, t)
                  else ...<Widget>[
                    Text(
                      waiting
                          ? l.lockRetryIn(_mmss(wait))
                          : _error ?? l.lockEnterPin,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(
                          color: waiting || _error != null
                              ? c.expense
                              : c.textMuted),
                    ),
                    const SizedBox(height: DsSpacing.xl),
                    PinEntry(
                      key: _pin,
                      enabled: !waiting,
                      autoSubmitLength: s.config.pinLength,
                      onSubmit: (String p) => _submit(l, p),
                      extraKey: s.config.deviceUnlock
                          ? IconButton(
                              tooltip: l.lockUseDevice,
                              iconSize: 30,
                              icon: Icon(Icons.fingerprint_rounded,
                                  color: c.brand),
                              onPressed: () => _device(l),
                            )
                          : null,
                    ),
                    const SizedBox(height: DsSpacing.md),
                    TextButton(
                      onPressed: () => setState(() => _forgot = true),
                      child: Text(l.lockForgot),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _forgotView(AppLocalizations l, DsColors c, TextTheme t) {
    return <Widget>[
      const SizedBox(height: DsSpacing.lg),
      Text(l.lockForgotBody,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.textMuted, height: 1.5)),
      const SizedBox(height: DsSpacing.xl),
      DsButton(
        label: l.lockEraseRestart,
        icon: Icons.delete_forever_outlined,
        expand: true,
        onPressed: () => ref.read(appLockProvider.notifier).eraseAndRestart(),
      ),
      const SizedBox(height: DsSpacing.sm),
      DsButton(
        label: l.lockBack,
        variant: DsButtonVariant.ghost,
        expand: true,
        onPressed: () => setState(() => _forgot = false),
      ),
    ];
  }
}
