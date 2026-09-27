import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/app_lock/application/app_lock_controller.dart';
import 'package:smartbudget/features/app_lock/presentation/pin_entry.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

enum PinSheetMode {
  /// New PIN + confirmation. Pops the new PIN.
  create,

  /// Current PIN, then new + confirmation. Pops the new PIN.
  change,

  /// Current PIN only. Pops the PIN once it matches.
  verify,
}

enum _Step { current, fresh, confirm }

class PinSetupSheet extends ConsumerStatefulWidget {
  const PinSetupSheet({super.key, required this.mode});
  final PinSheetMode mode;

  static Future<String?> show(BuildContext context, PinSheetMode mode) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinSetupSheet(mode: mode),
    );
  }

  @override
  ConsumerState<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends ConsumerState<PinSetupSheet> {
  late _Step _step =
      widget.mode == PinSheetMode.create ? _Step.fresh : _Step.current;
  String _fresh = '';
  String? _error;

  void _submit(AppLocalizations l, String pin) {
    switch (_step) {
      case _Step.current:
        if (!ref.read(appLockProvider.notifier).checkPin(pin)) {
          setState(() => _error = l.lockWrongPin);
          return;
        }
        if (widget.mode == PinSheetMode.verify) {
          Navigator.of(context).pop(pin);
          return;
        }
        setState(() {
          _step = _Step.fresh;
          _error = null;
        });
      case _Step.fresh:
        setState(() {
          _fresh = pin;
          _step = _Step.confirm;
          _error = null;
        });
      case _Step.confirm:
        if (pin == _fresh) {
          Navigator.of(context).pop(pin);
          return;
        }
        setState(() {
          _fresh = '';
          _step = _Step.fresh;
          _error = l.pinMismatch;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final int currentLength = ref.watch(appLockProvider).config.pinLength;

    final String prompt = switch (_step) {
      _Step.current => l.pinCurrent,
      _Step.fresh => l.pinNew,
      _Step.confirm => l.pinConfirm,
    };

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.lock_outline_rounded, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.settingsLock,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.sm),
              Text(prompt, style: t.titleSmall),
              const SizedBox(height: DsSpacing.xs),
              SizedBox(
                height: 20,
                child: _error == null
                    ? null
                    : Text(_error!,
                        style: t.bodySmall?.copyWith(color: c.expense)),
              ),
              const SizedBox(height: DsSpacing.md),
              PinEntry(
                key: ValueKey<_Step>(_step),
                autoSubmitLength: switch (_step) {
                  _Step.current => currentLength,
                  _Step.fresh => null,
                  _Step.confirm => _fresh.length,
                },
                continueLabel: l.pinContinue,
                onSubmit: (String p) => _submit(l, p),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
