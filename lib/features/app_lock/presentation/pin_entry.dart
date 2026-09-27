import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// PIN dots + a phone-style keypad. Also accepts digits, Backspace and Enter
/// from a hardware keyboard.
///
/// With [autoSubmitLength] the PIN is submitted as soon as it is complete;
/// otherwise a Continue button submits once 4–6 digits are in.
class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.onSubmit,
    this.autoSubmitLength,
    this.extraKey,
    this.continueLabel,
    this.enabled = true,
  });

  final ValueChanged<String> onSubmit;
  final int? autoSubmitLength;

  /// Optional bottom-left key (e.g. unlock with fingerprint).
  final Widget? extraKey;
  final String? continueLabel;
  final bool enabled;

  static const int minLength = 4;
  static const int maxLength = 6;

  @override
  State<PinEntry> createState() => PinEntryState();
}

class PinEntryState extends State<PinEntry> {
  String _pin = '';
  final FocusNode _focus = FocusNode();

  void clear() => setState(() => _pin = '');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  int get _max => widget.autoSubmitLength ?? PinEntry.maxLength;

  void _digit(String d) {
    if (!widget.enabled || _pin.length >= _max) return;
    setState(() => _pin += d);
    if (widget.autoSubmitLength != null && _pin.length == _max) {
      final String p = _pin;
      widget.onSubmit(p);
    }
  }

  void _back() {
    if (!widget.enabled || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _continue() {
    if (widget.enabled && _pin.length >= PinEntry.minLength) {
      widget.onSubmit(_pin);
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final String? ch = e.character;
    if (ch != null && RegExp(r'^[0-9]$').hasMatch(ch)) {
      _digit(ch);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _back();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter ||
        e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _continue();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < _max; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length ? c.brand : Colors.transparent,
                      border: Border.all(
                          color: i < _pin.length ? c.brand : c.textFaint,
                          width: 1.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DsSpacing.xl),
            for (final List<String> row in const <List<String>>[
              <String>['1', '2', '3'],
              <String>['4', '5', '6'],
              <String>['7', '8', '9'],
            ])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final String d in row)
                    _Key(onTap: () => _digit(d), child: _digitText(context, d)),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                    width: 76,
                    height: 76,
                    child: Center(child: widget.extraKey)),
                _Key(onTap: () => _digit('0'), child: _digitText(context, '0')),
                _Key(
                  onTap: _back,
                  filled: false,
                  child: Icon(Icons.backspace_outlined,
                      color: c.textMuted, size: 22),
                ),
              ],
            ),
            if (widget.autoSubmitLength == null) ...<Widget>[
              const SizedBox(height: DsSpacing.lg),
              DsButton(
                label: widget.continueLabel ?? 'OK',
                expand: true,
                onPressed: _pin.length >= PinEntry.minLength && widget.enabled
                    ? _continue
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _digitText(BuildContext context, String d) => Text(d,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.w600));
}

class _Key extends StatelessWidget {
  const _Key({required this.onTap, required this.child, this.filled = true});
  final VoidCallback onTap;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: filled ? c.surfaceMuted : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 64, height: 64, child: Center(child: child)),
        ),
      ),
    );
  }
}
