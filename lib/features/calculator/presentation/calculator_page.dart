import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/number_style.dart';
import 'package:smartbudget/core/settings/number_style_controller.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/calculator/domain/calculator_engine.dart';
import 'package:smartbudget/features/calculator/presentation/calculator_tools.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A light calculator for everyday sums: on the device, nothing stored, no
/// currency imposed. Only the display listens to the state; the keys are
/// built once.
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final ValueNotifier<CalcState> _state =
      ValueNotifier<CalcState>(CalcState.initial);
  final FocusNode _focus = FocusNode(debugLabel: 'calculator');

  @override
  void dispose() {
    _state.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _press(CalcState Function(CalcState) key) {
    HapticFeedback.selectionClick();
    _state.value = key(_state.value);
  }

  /// A physical keyboard, when there is one: digits, + - * / x, % . , = and
  /// Enter, Backspace, Delete and Escape.
  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Typing in a field (a tool's rate) is that field's, not the keypad's.
    if (FocusManager.instance.primaryFocus != _focus) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey k = e.logicalKey;
    CalcState Function(CalcState)? action;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      action = Calculator.equals;
    } else if (k == LogicalKeyboardKey.backspace) {
      action = Calculator.backspace;
    } else if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.delete) {
      action = Calculator.clear;
    } else {
      final String? ch = e.character;
      if (ch != null && ch.length == 1) {
        final int? d = int.tryParse(ch);
        action = d != null
            ? (CalcState s) => Calculator.digit(s, d)
            : switch (ch) {
                '+' => (CalcState s) => Calculator.op(s, CalcOp.add),
                '-' => (CalcState s) => Calculator.op(s, CalcOp.subtract),
                '*' || 'x' || 'X' =>
                  (CalcState s) => Calculator.op(s, CalcOp.multiply),
                '/' => (CalcState s) => Calculator.op(s, CalcOp.divide),
                '%' => Calculator.percent,
                '.' || ',' => Calculator.decimalPoint,
                '=' => Calculator.equals,
                _ => null,
              };
      }
    }
    if (action == null) return KeyEventResult.ignored;
    _state.value = action(_state.value);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    // The keypad is laid out like most calculators in every language (the
    // operators on the right); labels and announcements follow the app's
    // language.
    final List<_Key> keys = <_Key>[
      _Key.accent('AC', l.calcClear, Calculator.clear, id: 'clear'),
      _Key.icon(Icons.backspace_outlined, l.calcBackspace, Calculator.backspace,
          id: 'backspace'),
      _Key.accent('%', l.calcPercent, Calculator.percent, id: 'percent'),
      _Key.op('÷', l.calcDivide, CalcOp.divide),
      _Key.digit(7), _Key.digit(8), _Key.digit(9),
      _Key.op('×', l.calcMultiply, CalcOp.multiply),
      _Key.digit(4), _Key.digit(5), _Key.digit(6),
      _Key.op('−', l.calcSubtract, CalcOp.subtract),
      _Key.digit(1), _Key.digit(2), _Key.digit(3),
      _Key.op('+', l.calcAdd, CalcOp.add),
      _Key.fn('±', l.calcToggleSign, Calculator.toggleSign, id: 'sign'),
      _Key.digit(0),
      _Key.decimal(l.calcDecimal),
      _Key.equals(l.calcEquals),
    ];

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double width =
              box.maxWidth.clamp(0, 440).toDouble() - 2 * DsSpacing.lg;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(l.navCalculator,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: DsSpacing.lg),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _Display(state: _state),
                          const Divider(height: DsSpacing.xl),
                          // Like most calculators, whatever the language: 7 8 9
                          // from the left, the operators down the right.
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: DsSpacing.md,
                            crossAxisSpacing: DsSpacing.md,
                            childAspectRatio: 1.25,
                            children: <Widget>[
                              for (final _Key k in keys)
                                _KeyButton(
                                  keyDef: k,
                                  colors: c,
                                  onPressed: () => _press(k.action),
                                ),
                            ],
                          ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    CalculatorTools(
                      state: _state,
                      onUse: (CalcNumber v) => _state.value =
                          CalcState(accumulator: v, result: true),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The sum being worked out ("1,250 + 850") and its result under it, the
/// only part rebuilt on each key.
class _Display extends ConsumerWidget {
  const _Display({required this.state});
  final ValueNotifier<CalcState> state;

  static String _opSign(CalcOp op) => switch (op) {
        CalcOp.add => '+',
        CalcOp.subtract => '−',
        CalcOp.multiply => '×',
        CalcOp.divide => '÷',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NumberStyle style = ref.watch(numberStyleProvider);
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    String fmt(String plain) =>
        CalcFormat.format(plain, group: style.group, decimal: style.decimal);
    String num(CalcNumber n) => fmt(n.plain());

    return ValueListenableBuilder<CalcState>(
      valueListenable: state,
      builder: (BuildContext context, CalcState s, Widget? _) {
        // The sum: while an operation is pending, or the one that gave the
        // result shown.
        String sum = '';
        if (s.error == null) {
          if (s.pending != null && s.accumulator != null) {
            final String right = s.entry == null ? '' : ' ${fmt(s.entry!)}';
            sum = '${num(s.accumulator!)} ${_opSign(s.pending!)}$right';
          } else if (s.result && s.lastLeft != null && s.lastOp != null &&
              s.lastOperand != null) {
            sum = '${num(s.lastLeft!)} ${_opSign(s.lastOp!)} '
                '${num(s.lastOperand!)}';
          }
        }
        // Under it: the error, the result, the answer so far, or the number
        // being typed.
        final CalcNumber? preview = Calculator.preview(s);
        final String main = switch (s.error) {
          CalcError.divideByZero => l.calcDivideByZero,
          CalcError.tooLarge => l.calcTooLarge,
          null => s.pending != null && !s.result
              ? (preview == null ? '' : num(preview))
              : fmt(Calculator.display(s)),
        };
        final bool settled = s.result || s.error != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.calcCurrent,
                style: t.labelMedium?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                height: 44,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(sum,
                      key: const Key('calc-line'),
                      maxLines: 1,
                      style: t.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: settled ? c.textMuted : c.textPrimary)),
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.xs),
            SizedBox(
              height: 56,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: s.error == null
                    ? Alignment.centerLeft
                    : AlignmentDirectional.centerStart,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    main,
                    key: const Key('calc-display'),
                    maxLines: 1,
                    textDirection: s.error == null
                        ? TextDirection.ltr
                        : Directionality.of(context),
                    style: t.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: s.error != null
                          ? c.expense
                          : (settled || s.pending == null
                              ? c.textPrimary
                              : c.textMuted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _KeyKind { digit, fn, op, equals }

class _Key {
  const _Key._(this.label, this.semantic, this.action, this.kind, this.id,
      {this.icon});

  factory _Key.digit(int d) => _Key._('$d', '$d',
      (CalcState s) => Calculator.digit(s, d), _KeyKind.digit, 'd$d');

  factory _Key.decimal(String semantic) => _Key._(
      '.', semantic, Calculator.decimalPoint, _KeyKind.digit, 'decimal');

  factory _Key.fn(String label, String semantic,
          CalcState Function(CalcState) action, {required String id}) =>
      _Key._(label, semantic, action, _KeyKind.fn, id);

  factory _Key.accent(String label, String semantic,
          CalcState Function(CalcState) action, {required String id}) =>
      _Key._(label, semantic, action, _KeyKind.op, id);

  factory _Key.icon(IconData icon, String semantic,
          CalcState Function(CalcState) action, {required String id}) =>
      _Key._('', semantic, action, _KeyKind.fn, id, icon: icon);

  factory _Key.op(String label, String semantic, CalcOp op) => _Key._(
      label,
      semantic,
      (CalcState s) => Calculator.op(s, op),
      _KeyKind.op,
      'op-${op.name}');

  factory _Key.equals(String semantic) =>
      _Key._('=', semantic, Calculator.equals, _KeyKind.equals, 'equals');

  final String label;
  final String semantic;
  final CalcState Function(CalcState) action;
  final _KeyKind kind;
  final String id;
  final IconData? icon;
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.keyDef,
    required this.colors,
    required this.onPressed,
  });

  final _Key keyDef;
  final DsColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final DsColors c = colors;
    final (Color bg, Color fg) = switch (keyDef.kind) {
      // Operators, %, AC and = in the brand blue; digits and the quiet keys
      // in the card's grey.
      _KeyKind.equals || _KeyKind.op => (c.brand, Colors.white),
      _KeyKind.fn || _KeyKind.digit => (c.surfaceMuted, c.textPrimary),
    };
    final TextStyle? style = Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: fg,
        fontWeight:
            keyDef.kind == _KeyKind.digit ? FontWeight.w500 : FontWeight.w600);
    return Semantics(
      button: true,
      label: keyDef.semantic,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: DsRadius.brLg,
        child: InkWell(
          key: Key('calc-${keyDef.id}'),
          borderRadius: DsRadius.brLg,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: DsRadius.brLg,
              border: keyDef.kind == _KeyKind.equals ||
                      keyDef.kind == _KeyKind.op
                  ? null
                  : Border.all(color: c.border.withValues(alpha: 0.35)),
            ),
            child: keyDef.icon != null
                ? Icon(keyDef.icon, color: fg, size: 24)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(keyDef.label, style: style),
                  ),
          ),
        ),
      ),
    );
  }
}
