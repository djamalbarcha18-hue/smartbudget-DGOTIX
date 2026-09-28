import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/presentation/pin_entry.dart';
import 'package:smartbudget/features/app_lock/presentation/recovery_code_view.dart';
import 'package:smartbudget/features/backup/application/backup_status_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The lock screen's steps. "Forgot PIN" leads either to the recovery code
/// (new PIN, data kept) or, without it, to a confirmed erase.
enum _View { pin, forgot, recovery, newPin, confirmPin, newCode, erase }

/// Full-screen lock shown over the whole app while it is locked.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final GlobalKey<PinEntryState> _pin = GlobalKey<PinEntryState>();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _confirmWord = TextEditingController();
  String? _error;
  _View _view = _View.pin;
  String _newPin = '';
  String? _newCode;
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
    _code.dispose();
    _confirmWord.dispose();
    super.dispose();
  }

  void _go(_View v) => setState(() {
        _view = v;
        _error = null;
      });

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

  void _checkRecovery(AppLocalizations l) {
    final PinResult r =
        ref.read(appLockProvider.notifier).checkRecovery(_code.text);
    if (r == PinResult.ok) {
      _go(_View.newPin);
      return;
    }
    setState(() => _error = r == PinResult.wrong ? l.lockRecoveryWrong : null);
  }

  Future<void> _newPinStep(AppLocalizations l, String pin) async {
    if (_view == _View.newPin) {
      setState(() {
        _newPin = pin;
        _view = _View.confirmPin;
        _error = null;
      });
      return;
    }
    if (pin != _newPin) {
      setState(() {
        _newPin = '';
        _view = _View.newPin;
        _error = l.pinMismatch;
      });
      return;
    }
    final String? fresh = await ref
        .read(appLockProvider.notifier)
        .resetWithRecovery(_code.text, pin);
    if (!mounted) return;
    if (fresh == null) {
      _go(_View.recovery);
      return;
    }
    setState(() {
      _newCode = fresh;
      _view = _View.newCode;
      _error = null;
    });
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
    final Duration wait = ref.read(appLockProvider.notifier).waitRemaining;
    final bool erase = _view == _View.erase;
    final bool key = _view == _View.recovery || _view == _View.newCode;

    final List<Widget> body = switch (_view) {
      _View.pin => _pinView(l, c, t, wait),
      _View.forgot => _forgotView(l, c, t),
      _View.recovery => _recoveryView(l, c, t, wait),
      _View.newPin || _View.confirmPin => _newPinView(l, c, t),
      _View.newCode => <Widget>[
          const SizedBox(height: DsSpacing.lg),
          RecoveryCodeView(
            code: _newCode!,
            message: l.lockNewCodeAfterReset,
            doneLabel: l.lockOpenApp,
            onDone: () => ref.read(appLockProvider.notifier).finishRecovery(),
          ),
        ],
      _View.erase => _eraseView(l, c, t),
    };

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
                      color: (erase ? c.expense : c.brand)
                          .withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        erase
                            ? Icons.warning_amber_rounded
                            : key
                                ? Icons.key_rounded
                                : Icons.lock_rounded,
                        color: erase ? c.expense : c.brand,
                        size: 30),
                  ),
                  const SizedBox(height: DsSpacing.md),
                  Text(
                      erase
                          ? l.lockEraseTitle
                          : key
                              ? l.lockRecoveryTitle
                              : l.lockTitle(AppConfig.appName),
                      textAlign: TextAlign.center,
                      style:
                          t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: DsSpacing.xs),
                  ...body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _status(String text, Color color, TextTheme t) => Text(
        text,
        textAlign: TextAlign.center,
        style: t.bodyMedium?.copyWith(color: color),
      );

  List<Widget> _pinView(
      AppLocalizations l, DsColors c, TextTheme t, Duration wait) {
    final AppLockState s = ref.watch(appLockProvider);
    final bool waiting = wait > Duration.zero;
    return <Widget>[
      _status(
          waiting ? l.lockRetryIn(_mmss(wait)) : _error ?? l.lockEnterPin,
          waiting || _error != null ? c.expense : c.textMuted,
          t),
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
                icon: Icon(Icons.fingerprint_rounded, color: c.brand),
                onPressed: () => _device(l),
              )
            : null,
      ),
      const SizedBox(height: DsSpacing.md),
      TextButton(
        onPressed: () => _go(_View.forgot),
        child: Text(l.lockForgot),
      ),
    ];
  }

  List<Widget> _forgotView(AppLocalizations l, DsColors c, TextTheme t) {
    final bool hasRecovery = ref.watch(
        appLockProvider.select((AppLockState s) => s.config.hasRecovery));
    return <Widget>[
      const SizedBox(height: DsSpacing.lg),
      Text(hasRecovery ? l.lockForgotWithRecovery : l.lockForgotBody,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.textMuted, height: 1.5)),
      const SizedBox(height: DsSpacing.xl),
      if (hasRecovery) ...<Widget>[
        DsButton(
          label: l.lockHaveRecovery,
          icon: Icons.key_rounded,
          expand: true,
          onPressed: () {
            _code.clear();
            _go(_View.recovery);
          },
        ),
        const SizedBox(height: DsSpacing.sm),
      ],
      DsButton(
        label: hasRecovery ? l.lockNoCodeErase : l.lockEraseRestart,
        icon: Icons.delete_forever_outlined,
        variant:
            hasRecovery ? DsButtonVariant.secondary : DsButtonVariant.primary,
        expand: true,
        onPressed: () {
          _confirmWord.clear();
          _go(_View.erase);
        },
      ),
      const SizedBox(height: DsSpacing.sm),
      _backButton(l, _View.pin),
    ];
  }

  List<Widget> _recoveryView(
      AppLocalizations l, DsColors c, TextTheme t, Duration wait) {
    final bool waiting = wait > Duration.zero;
    return <Widget>[
      _status(
          waiting ? l.lockRetryIn(_mmss(wait)) : _error ?? l.lockEnterRecovery,
          waiting || _error != null ? c.expense : c.textMuted,
          t),
      const SizedBox(height: DsSpacing.lg),
      Directionality(
        textDirection: TextDirection.ltr,
        child: TextField(
          controller: _code,
          enabled: !waiting,
          autofocus: true,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          style: t.titleMedium?.copyWith(letterSpacing: 2),
          decoration: _fieldDecoration(c, 'XXXX-XXXX-XXXX'),
          onSubmitted: (_) => _checkRecovery(l),
        ),
      ),
      const SizedBox(height: DsSpacing.lg),
      DsButton(
        label: l.lockVerify,
        icon: Icons.check_rounded,
        expand: true,
        onPressed: waiting ? null : () => _checkRecovery(l),
      ),
      const SizedBox(height: DsSpacing.sm),
      _backButton(l, _View.forgot),
    ];
  }

  List<Widget> _newPinView(AppLocalizations l, DsColors c, TextTheme t) {
    final bool confirm = _view == _View.confirmPin;
    return <Widget>[
      _status(_error ?? (confirm ? l.pinConfirm : l.pinNew),
          _error != null ? c.expense : c.textMuted, t),
      const SizedBox(height: DsSpacing.xl),
      PinEntry(
        key: ValueKey<_View>(_view),
        autoSubmitLength: confirm ? _newPin.length : null,
        continueLabel: l.pinContinue,
        onSubmit: (String p) => _newPinStep(l, p),
      ),
    ];
  }

  List<Widget> _eraseView(AppLocalizations l, DsColors c, TextTheme t) {
    final DateTime? last = ref.watch(backupStatusProvider)?.lastBackup;
    final String word = l.lockEraseWord;
    final bool confirmed =
        _confirmWord.text.trim().toUpperCase() == word.toUpperCase();

    return <Widget>[
      const SizedBox(height: DsSpacing.md),
      Text(l.lockEraseWarning,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.textMuted, height: 1.5)),
      const SizedBox(height: DsSpacing.md),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DsSpacing.md),
        decoration: BoxDecoration(
          color: last == null
              ? c.expense.withValues(alpha: 0.10)
              : c.surfaceMuted,
          borderRadius: DsRadius.brMd,
          border: Border.all(
              color:
                  last == null ? c.expense.withValues(alpha: 0.4) : c.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
                last == null
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_outlined,
                size: 20,
                color: last == null ? c.expense : c.income),
            const SizedBox(width: DsSpacing.sm),
            Expanded(
              child: Text(
                  last == null
                      ? l.lockNoBackup
                      : l.lockLastBackup(isoDate(last)),
                  style: t.bodySmall?.copyWith(color: c.textPrimary)),
            ),
          ],
        ),
      ),
      const SizedBox(height: DsSpacing.lg),
      Text(l.lockEraseTypeHint(word),
          style: t.labelMedium?.copyWith(color: c.textMuted)),
      const SizedBox(height: DsSpacing.xs),
      TextField(
        controller: _confirmWord,
        textAlign: TextAlign.center,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) => setState(() {}),
        decoration: _fieldDecoration(c, word),
      ),
      const SizedBox(height: DsSpacing.lg),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: c.expense,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: DsRadius.brMd),
        ),
        onPressed: confirmed
            ? () => ref.read(appLockProvider.notifier).eraseAndRestart()
            : null,
        icon: const Icon(Icons.delete_forever_outlined, size: 18),
        label: Text(l.lockEraseNow),
      ),
      const SizedBox(height: DsSpacing.sm),
      _backButton(l, _View.forgot),
    ];
  }

  InputDecoration _fieldDecoration(DsColors c, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textFaint),
        filled: true,
        fillColor: c.surfaceMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: DsRadius.brMd,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DsRadius.brMd,
          borderSide: BorderSide(color: c.brand),
        ),
      );

  Widget _backButton(AppLocalizations l, _View to) => DsButton(
        label: l.lockBack,
        variant: DsButtonVariant.ghost,
        expand: true,
        onPressed: () => _go(to),
      );
}
